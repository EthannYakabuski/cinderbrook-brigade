extends SceneTree
const Profile=preload("res://game/profile.gd")
const Run=preload("res://game/run.gd")
const ModelTests=preload("res://tests/test_model.gd")
var checks:=0
var failures:Array=[]
var save_path:="user://qa-profile-tests.json"

func check(value:bool,message:String) -> void:
	checks+=1
	if not value:failures.append(message);printerr("FAIL: "+message)

func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--qa-profile=user://qa-"):save_path=arg.trim_prefix("--qa-profile=")
	for suffix in ["",".bak",".tmp",".recovery.tmp",".corrupt"]:
		if FileAccess.file_exists(save_path+suffix):DirAccess.remove_absolute(save_path+suffix)
	var p:=Profile.new(save_path);check(Profile.valid(p.data),"defaults valid")
	check(p.login(20771)==35,"first gift35");check(p.login(20771)==0,"login exactly once");check(p.login(20770)==0,"rollback no gift")
	for day in range(20772,20778):check(p.login(day)==Profile.login_reward(day-20770),"consecutive gift %d"%day)
	check(p.data.streak==7 and p.data.records.best_streak==7,"seven-day reward track");check(p.login(20778)==35 and p.data.streak==1,"streak wraps after7");check(p.login(20780)==35 and p.data.streak==1,"gap resets streak")
	var reloaded:=Profile.new(save_path);check(reloaded.data.coins==p.data.coins,"coins persisted");check(reloaded.data.sequence==p.data.sequence,"primary sequence preserved")
	var before:int=p.data.coins;check(p.purchase("pump"),"affordable purchase");check(p.data.gear.pump==1 and p.data.coins==before-55,"exact purchase transaction");check(not p.purchase("unknown"),"unknown purchase rejected")
	reloaded=Profile.new(save_path);check(reloaded.data.gear.pump==1,"purchase reload")
	var id:int=p.new_run();check(id>0,"allocate run");var run:=Run.new();run.start(id,"campaign",0,p.data.gear,20780);check(p.store_run(run.snapshot()),"active run stored");check(p.new_run()==0,"cannot replace unfinished run")
	run.advance(0.2,Vector2(-1.4,0),true);check(p.store_run(run.snapshot()),"active input saved");reloaded=Profile.new(save_path);var restored:RefCounted=Run.restore(reloaded.data.active);check(is_equal_approx(restored.elapsed,run.elapsed) and is_equal_approx(restored.water,run.water),"active exact reload")
	ModelTests.solve(run);check(run.won,"fixture played model won");var receipt:Dictionary=p.settle(run,20780);check(not receipt.is_empty() and receipt.coins>0 and receipt.xp>0,"completion reward");check(p.data.stars[0]==3 and p.frontier()==1,"star/frontier progress")
	before=p.data.coins;check(p.settle(run,20780).is_empty() and p.data.coins==before,"duplicate settlement rejected")
	reloaded=Profile.new(save_path);check(reloaded.data.active.is_empty() and reloaded.data.coins==before,"settlement restart durable")
	var untouched:=Run.new();untouched.start(p.new_run(),"campaign",1,p.data.gear,20780);check(p.store_run(untouched.snapshot()),"untouched run stored");before=p.data.coins;check(p.abandon() and p.data.coins==before,"untouched abandon no payout")
	var idle:=Run.new();idle.start(p.new_run(),"campaign",0,{},20780)
	for i in range(3000):
		if idle.done:break
		idle.advance(1.0/30,Vector2.ZERO,false)
	var idle_receipt:Dictionary=p.settle(idle,20780);check(idle_receipt.coins==0 and idle_receipt.xp==0,"idle failure no payout")
	var daily:=Run.new();daily.start(p.new_run(),"daily",0,{},20780);ModelTests.solve(daily);var perfect_before:int=p.data.totals.perfect;receipt=p.settle(daily,20780);check(p.data.daily_paid==20780 and p.data.totals.daily_clears==1,"daily completion date");check(p.data.totals.perfect==perfect_before,"daily does not unlock campaign3star metric")
	daily=Run.new();daily.start(p.new_run(),"daily",0,{},20780);ModelTests.solve(daily);var again:Dictionary=p.settle(daily,20780);check(receipt.coins-again.coins==70 and receipt.xp-again.xp==100,"daily bonus once");check(p.data.totals.daily_clears==1,"distinct daily days")
	var n:Dictionary=p.data.duplicate(true);n.quest={"doused":20,"clears":3,"prevented":2};check(p.commit(n),"quest fixture valid");check(p.claim_quest("doused",20780),"earned quest claim");before=p.data.coins;check(not p.claim_quest("doused",20780) and p.data.coins==before,"quest duplicate denied");check(not p.claim_quest("clears",20779),"quest wrong day denied")
	var cat:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://game/catalog.json"));var unlocked:Array=p.update_achievements(cat);check("first_response" in unlocked and "three_star" in unlocked,"local achievements update");check(p.update_achievements(cat).is_empty(),"achievement unlock idempotent")
	check(p.setting("music",false),"settings transaction");check(not Profile.new(save_path).data.music,"settings persisted")
	var recovery_run:=Run.new();recovery_run.start(p.new_run(),"campaign",0,{},20780)
	for i in range(3000):
		if recovery_run.done:break
		recovery_run.advance(1.0/30,Vector2.ZERO,false)
	check(recovery_run.mark_recovery_earned() and p.store_run(recovery_run.snapshot()),"earned pending persisted");reloaded=Profile.new(save_path);restored=Run.restore(reloaded.data.active);check(restored.done and restored.recovery_earned,"pending restart remains failure before apply");check(restored.apply_recovery() and reloaded.store_run(restored.snapshot()),"recovery committed once");p=Profile.new(save_path);restored=Run.restore(p.data.active);check(restored.recovery_used and not restored.recovery_earned and not restored.done,"post-recovery restart idempotent")
	var invalid:Dictionary=p.data.duplicate(true);invalid.coins=-1;check(not p.commit(invalid),"negative wallet rejected");invalid=p.data.duplicate(true);invalid.active.spec={};check(not Profile.valid(invalid),"nested unknown snapshot field rejected")
	var saved_sequence:int=p.data.sequence
	var file:=FileAccess.open(save_path,FileAccess.WRITE);file.store_string("{broken");file.close();var recovered:=Profile.new(save_path);check(Profile.valid(recovered.data) and not recovered.recovery.is_empty(),"corrupt primary recovers backup");check(FileAccess.file_exists(save_path+".corrupt"),"corrupt bytes preserved");check(recovered.data.sequence>=saved_sequence,"recovery sequence advances")
	# A completed staged write survives an interrupted rename and wins by sequence.
	var stage:Dictionary=recovered.data.duplicate(true);stage.sequence+=10;stage.coins+=7;file=FileAccess.open(save_path+".tmp",FileAccess.WRITE);file.store_string(JSON.stringify(stage));file.close();var staged:=Profile.new(save_path);check(staged.data.coins==stage.coins,"newest complete staged progress recovered");check(staged.data.sequence>stage.sequence,"staged recovery committed")
	# Failed storage must not mutate the in-memory wallet or create a later phantom purchase.
	var unavailable:=Profile.new("user://qa-does-not-exist/sub/profile.json");unavailable.data.coins=100;var old:Dictionary=unavailable.data.duplicate(true);check(not unavailable.purchase("pump"),"unavailable storage purchase rejected");check(unavailable.data==old,"failed write leaves wallet unchanged")
	if failures.is_empty():print("PROFILE PASS checks=%d"%checks);quit(0)
	else:printerr("PROFILE FAILED %d / %d"%[failures.size(),checks]);quit(1)
