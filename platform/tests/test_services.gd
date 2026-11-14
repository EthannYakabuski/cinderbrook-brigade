extends Node
## Deterministic callback fixtures; these do not claim native SDK delivery.

const Adapter = preload("res://platform/services.gd")
var failures: Array[String] = []
var checks := 0

class Harness extends "res://platform/services.gd":
	func _ready() -> void: pass
	func _load_interstitial() -> void: pass
	func _load_rewarded() -> void: pass

class StorageFailHarness extends Harness:
	func _save_pending() -> bool: return false

class RewardFixture extends RewardedAd:
	var requested := 0
	var destroyed := false
	var listener: OnUserEarnedRewardListener
	func _init(): super(101)
	func show(value := OnUserEarnedRewardListener.new()) -> void:
		listener = value
		requested += 1
	func destroy() -> void: destroyed = true

class InterstitialFixture extends InterstitialAd:
	var requested := 0
	var destroyed := false
	func _init(): super(102)
	func show() -> void: requested += 1
	func destroy() -> void: destroyed = true

class AchievementsFixture extends PlayGamesAchievementsClient:
	var requests: Array[String] = []
	func unlock_achievement(id: String) -> void: requests.append(id)

class ScoresFixture extends PlayGamesLeaderboardsClient:
	var requests: Array = []
	func submit_score(id: String, value: int) -> void: requests.append([id, value])

func _ready() -> void:
	run.call_deferred()

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures.append(description)
		push_error(description)

func run() -> void:
	var service := Harness.new()
	service.settings = JSON.parse_string(FileAccess.get_file_as_string("res://platform/config.json"))
	service.settings.play_games.achievements = {"fixture_first": ""}
	service.settings.play_games.leaderboards = {"best_score": "", "fixture_xp": ""}
	service.pending_path = "user://platform-fixture-%d.json" % Time.get_ticks_usec()
	add_child(service)
	var rewards: Array = []
	var earned_checkpoints: Array = []
	service.reward_earned.connect(func(): earned_checkpoints.append("earned"))
	var events: Array = []
	service.reward_finished.connect(func(earned: bool): rewards.append(earned))
	service.fullscreen_pending.connect(func(reason: String): events.append("pending:" + reason))
	service.fullscreen_visibility_changed.connect(func(showing: bool): events.append("visibility:" + str(showing)))
	check(not service.request_rewarded_continue(), "Desktop/offline requests refuse")
	await get_tree().process_frame
	check(rewards == [false], "Unavailable request reports unearned")
	service._earned_reward(null, service._reward_generation)
	check(not service._reward_granted and earned_checkpoints.is_empty(), "Stray earned callback cannot mint reward or checkpoint")
	service._native_ads = true
	service._ads_ready = true
	var rewarded := RewardFixture.new()
	service._rewarded = rewarded
	check(service.request_rewarded_continue(), "Available opt-in reward starts")
	check(service.fullscreen_ad_active() and events == ["pending:rewarded"], "Request freezes before SDK display")
	check(not service.request_rewarded_continue() and rewarded.requested == 1, "Double request does not replace active reward")
	rewarded.full_screen_content_callback.on_ad_showed_full_screen_content.call()
	rewarded.listener.on_user_earned_reward.call(null)
	rewarded.listener.on_user_earned_reward.call(null)
	check(rewards == [false] and service.fullscreen_ad_active(), "Earned signal defers finalization until dismissal")
	check(earned_checkpoints == ["earned"], "A genuine callback emits one durable-checkpoint opportunity while fullscreen remains locked")
	rewarded.full_screen_content_callback.on_ad_dismissed_full_screen_content.call()
	check(rewards == [false, true] and not service.fullscreen_ad_active(), "Earned dismissal resolves exactly once")
	rewarded.full_screen_content_callback.on_ad_dismissed_full_screen_content.call()
	rewarded.listener.on_user_earned_reward.call(null)
	check(rewards == [false, true] and earned_checkpoints == ["earned"], "Repeated and late callbacks cannot duplicate a checkpoint or grant")
	var cancelled := RewardFixture.new()
	service._rewarded = cancelled
	service.request_rewarded_continue()
	rewarded.listener.on_user_earned_reward.call(null)
	check(not service._reward_granted, "Old request cannot award a later request")
	cancelled.full_screen_content_callback.on_ad_dismissed_full_screen_content.call()
	check(rewards == [false, true, false], "Cancellation gives no entitlement")
	var failed := RewardFixture.new()
	service._rewarded = failed
	service.request_rewarded_continue()
	failed.listener.on_user_earned_reward.call(null)
	service._rewarded_closed(service._reward_generation, true)
	check(rewards == [false, true, false, false], "Failed show never grants even after contradictory earned callback")
	service._consent_showing = true
	check(not service.can_reward() and service.fullscreen_ad_active(), "Consent form blocks fullscreen and gameplay")
	service._consent_showing = false
	var interstitial := InterstitialFixture.new()
	service._interstitial = interstitial
	var transitions: Array = []
	service.interstitial_finished.connect(func(shown: bool): transitions.append(shown))
	service.record_round_completed("round-a")
	service.record_round_completed("round-a")
	service.record_round_completed("round-b")
	check(service._round_count == 2 and not service.request_interstitial_at_transition(), "Repeated results do not count and first two rounds have no interstitial")
	await get_tree().process_frame
	service.record_round_completed("round-c")
	check(interstitial.requested == 0, "Third completed round does not interrupt results")
	check(service.request_interstitial_at_transition() and interstitial.requested == 1, "Third transition starts interstitial")
	check(service.fullscreen_ad_active(), "Interstitial request is a pending fullscreen block")
	interstitial.full_screen_content_callback.on_ad_showed_full_screen_content.call()
	interstitial.full_screen_content_callback.on_ad_dismissed_full_screen_content.call()
	interstitial.full_screen_content_callback.on_ad_dismissed_full_screen_content.call()
	check(transitions == [false, true] and not service.fullscreen_ad_active(), "Interstitial dismisses once")
	check(not service.request_interstitial_at_transition(), "One opportunity per completed third round")
	var old_generation: int = service._ad_load_generation
	service._destroy_loaded_ads()
	service._ads_ready = false
	service._ads_initializing = true
	service._on_ads_initialized(null, old_generation)
	check(not service._ads_ready and service._ads_initializing, "Old consent initialization cannot enable ads or clear newer initialization")
	service._consent_showing = true
	service._on_ads_initialized(null, service._ad_load_generation)
	check(not service._ads_ready and not service._ads_initializing, "Initialization during privacy choices never requests ads")
	service._consent_showing = false
	service._ads_ready = true
	service._rewarded_loading = true
	service._interstitial_loading = true
	var stale_reward := RewardFixture.new()
	var stale_interstitial := InterstitialFixture.new()
	service._rewarded_loaded(stale_reward, old_generation)
	service._interstitial_loaded(stale_interstitial, old_generation)
	check(stale_reward.destroyed and stale_interstitial.destroyed and service._rewarded == null and service._interstitial == null, "Ads loaded under previous consent are destroyed")
	service._ad_load_failed("rewarded", null, old_generation)
	check(service._rewarded_loading and service._interstitial_loading, "Stale success/failure does not clear current consent load flags")
	var current_reward := RewardFixture.new()
	service._rewarded_loaded(current_reward, service._ad_load_generation)
	check(service._rewarded == current_reward and not service._rewarded_loading, "Current consent load is accepted")
	service._destroy_loaded_ads()
	check(Adapter._menu_reserve_from_pixels(150, 60, 3, 3) == 82, "Banner pixels, safe inset and gap scale once")
	check(Adapter._menu_safe_bottom_pixels(1920, 1920, 0, 0, 2, false) == 96, "Missing Android safe area cannot consume screen")
	check(Adapter._ad_id_for_build({"admob": {"test_mode": false, "rewarded_unit_id": "production"}}, "rewarded", true) == Adapter.TEST_AD_UNIT_IDS.rewarded, "Debug always uses Google test units")
	check(Adapter._metric_value({"n": NAN}, "n") == -1 and Adapter._metric_value({"n": 2.5}, "n") == -1, "Nonfinite or fractional metrics rejected")
	service.configure_catalog({"achievements": [{"id": "fixture_first", "metric": "rescues", "threshold": 1}], "leaderboards": [{"id": "best_score", "metric": "best_score"}]})
	service.submit_metrics({"rescues": 1, "best_score": 100})
	service.submit_metrics({"rescues": 0, "best_score": 50})
	check(service._pending_unlocks.has("fixture_first") and service._pending_scores.best_score == 100, "Catalog unlocks and best scores persist while disabled")
	var file := FileAccess.open(service.pending_path + ".tmp", FileAccess.WRITE)
	file.store_string('{"schema_version":1,"unlocks":{"fixture_first":true,"unknown":true},"scores":{"best_score":150,"fixture_xp":-2}}')
	file.close()
	file = FileAccess.open(service.pending_path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	service._load_pending()
	check(service._pending_scores.best_score == 150 and not service._pending_scores.has("fixture_xp") and not service._pending_unlocks.has("unknown"), "Corrupt main recovers valid best pending values and rejects unknown/negative keys")
	file = FileAccess.open(service.pending_path, FileAccess.WRITE)
	file.store_string('{"schema_version":{},"unlocks":{},"scores":{"best_score":999}}')
	file.close()
	service._load_pending()
	check(service._pending_scores.best_score == 150, "Malformed schema type is ignored without coercion or runtime error")
	var achievements := AchievementsFixture.new()
	var scores := ScoresFixture.new()
	service.add_child(achievements)
	service.add_child(scores)
	service._achievements_client = achievements
	service._leaderboards_client = scores
	service._pgs_ready = true
	service._signed_in = true
	service._flush_pending()
	check(scores.requests.is_empty() and achievements.requests.is_empty(), "Blank mappings never reach native clients")
	service.settings.play_games.achievements.fixture_first = "fixture-achievement"
	service.settings.play_games.leaderboards.best_score = "fixture-board"
	service._flush_pending()
	check(scores.requests == [["fixture-board", 150]] and achievements.requests == ["fixture-achievement"], "Configured native clients receive mapped catalog keys")
	service._achievement_submitted(true, "fixture-achievement")
	service._score_submitted(true, "fixture-board")
	service._flush_pending()
	check(scores.requests.size() == 1 and achievements.requests.size() == 1, "Success acknowledges current session without resubmitting")
	service.submit("best_score", 200)
	service._flush_pending()
	service._invalidate_play_games_requests()
	service.submit("best_score", 300)
	service._flush_pending()
	service._score_submitted(true, "fixture-board")
	check(int(service._submitted_scores.best_score.value) == 150 and service._pending_scores.best_score == 300, "Late ambiguous callback never acknowledges a newer score")
	service._score_submitted(false, "fixture-board")
	check(service._pgs_needs_auth_check and not service._submitted_scores.has("best_score"), "Late native failure schedules reconnect without losing progress")
	service._pgs_ready = false
	for path in [service.pending_path, service.pending_path + ".bak", service.pending_path + ".tmp"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	await get_tree().process_frame
	service.free()
	await test_cadence_persistence()
	print("PLATFORM_FIXTURES ", JSON.stringify({"checks": checks, "failures": failures, "native_sdk_proof": false}))
	get_tree().quit(0 if failures.is_empty() else 1)


func test_cadence_persistence() -> void:
	var cadence_path := "user://cadence-fixture-%d.json" % Time.get_ticks_usec()
	var base_settings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://platform/config.json"))
	var first := Harness.new()
	first.settings = base_settings.duplicate(true)
	first.pending_path = cadence_path
	add_child(first)
	first.record_round_completed("incident-1")
	first.record_round_completed("incident-2")
	var cold := Harness.new()
	cold.settings = base_settings.duplicate(true)
	cold.pending_path = cadence_path
	add_child(cold)
	cold._load_pending()
	check(cold._round_count == 2 and cold._last_interstitial_round == 0, "Cold restart retains two completed rounds")
	cold.record_round_completed("incident-2")
	check(cold._round_count == 2, "Cold duplicate settlement ID cannot advance cadence")
	cold.record_round_completed("incident-3")
	cold._native_ads = true
	cold._ads_ready = true
	var ad := InterstitialFixture.new()
	cold._interstitial = ad
	check(cold.request_interstitial_at_transition() and ad.requested == 1, "Third round after restart gets its natural-transition opportunity")
	var after_show := Harness.new()
	after_show.settings = base_settings.duplicate(true)
	after_show.pending_path = cadence_path
	add_child(after_show)
	after_show._load_pending()
	check(after_show._round_count == 3 and after_show._last_interstitial_round == 3, "Opportunity consumption is durable before native dismissal")
	check(not after_show.request_interstitial_at_transition(), "Restart during a displayed ad cannot replay the consumed opportunity")
	ad.full_screen_content_callback.on_ad_dismissed_full_screen_content.call()
	for id in ["incident-4", "incident-5", "incident-6"]:
		after_show.record_round_completed(id)
	check(not after_show.request_interstitial_at_transition(), "Unavailable sixth-round opportunity is skipped")
	var available_later := Harness.new()
	available_later.settings = base_settings.duplicate(true)
	available_later.pending_path = cadence_path
	add_child(available_later)
	available_later._load_pending()
	available_later._native_ads = true
	available_later._ads_ready = true
	var later_ad := InterstitialFixture.new()
	available_later._interstitial = later_ad
	check(available_later._round_count == 6 and available_later._last_interstitial_round == 6 and not available_later.request_interstitial_at_transition() and later_ad.requested == 0, "Later fill after restart cannot resurrect an unavailable opportunity")
	var failed := StorageFailHarness.new()
	failed.settings = base_settings.duplicate(true)
	failed._round_count = 3
	failed._native_ads = true
	failed._ads_ready = true
	var failed_ad := InterstitialFixture.new()
	failed._interstitial = failed_ad
	add_child(failed)
	check(not failed.request_interstitial_at_transition() and failed_ad.requested == 0 and not failed.fullscreen_ad_active(), "Failed consumption write refuses native display")
	check(not Adapter._valid_cadence({"round_count": {}, "consumed_round": 0, "completed_ids": {}}), "Wrong-type cadence count is rejected")
	check(not Adapter._valid_cadence({"round_count": 3, "consumed_round": 6, "completed_ids": {}}), "Future consumed round is rejected")
	check(not Adapter._valid_cadence({"round_count": 3, "consumed_round": 2, "completed_ids": {}}), "Only third-round opportunities can be marked consumed")
	check(not Adapter._valid_cadence({"round_count": 3, "consumed_round": 0, "completed_ids": {"incident-4": 4}}), "Future completed-ID ordinal is rejected")
	for ordinal in range(1, 301):
		available_later._completed_round_ids["bounded-%d" % ordinal] = ordinal
	available_later._round_count = 300
	available_later._prune_completed_round_ids()
	check(available_later._completed_round_ids.size() == Adapter.MAX_CADENCE_IDS and available_later._completed_round_ids.has("bounded-300") and not available_later._completed_round_ids.has("bounded-1"), "Retained stable IDs stay bounded and preserve newest rounds")
	await get_tree().process_frame
	for node in [first, cold, after_show, available_later, failed]:
		node.free()
	for filename in [cadence_path, cadence_path + ".bak", cadence_path + ".tmp"]:
		if FileAccess.file_exists(filename):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(filename))
