extends SceneTree
const Run=preload("res://game/run.gd")
const Profile=preload("res://game/profile.gd")
var checks:=0
var failures:Array=[]
var main:Node

func check(value:bool,message:String) -> void:
	checks+=1
	if not value:failures.append(message);printerr("FAIL: "+message)

func _init() -> void:call_deferred("run_tests")

func button_named(parent:Node,text:String) -> Button:
	if parent is Button and parent.text==text and parent.is_visible_in_tree():return parent
	for child in parent.get_children():
		var found:=button_named(child,text)
		if found:return found
	return null

func touch(pos:Vector2,pressed:bool,index:int=0) -> void:
	var event:=InputEventScreenTouch.new();event.position=pos;event.pressed=pressed;event.index=index;Input.parse_input_event(event)

func tap(b:Button) -> void:
	if b==null:check(false,"button exists for touch");return
	var point:=b.get_global_rect().get_center();touch(point,true);await process_frame;touch(point,false);await process_frame;await process_frame

func buttons_fit(parent:Node) -> void:
	if parent is Button and parent.is_visible_in_tree():
		var rect:Rect2=parent.get_global_rect();check(rect.size.y>=42,"touch target height "+parent.text);check(rect.position.x>=-1 and rect.end.x<=root.size.x+1,"button width "+parent.text)
		var ancestor:Node=parent.get_parent();var scrolling:=false
		while ancestor!=null:
			if ancestor is ScrollContainer:scrolling=true;break
			ancestor=ancestor.get_parent()
		if not scrolling:check(rect.position.y>=-1 and rect.end.y<=root.size.y+1,"button vertical viewport "+parent.text)
	for child in parent.get_children():buttons_fit(child)

func home_art_fits(context:String) -> void:
	check(is_instance_valid(main.home_art),context+" home artwork exists")
	if not is_instance_valid(main.home_art):return
	var art:TextureRect=main.home_art
	var rect:Rect2=art.get_rect()
	var viewport_size:Vector2=main.get_viewport().get_visible_rect().size
	var texture_size:Vector2=art.texture.get_size()
	check(is_zero_approx(rect.position.y),context+" title stays at the viewport top")
	check(is_equal_approx(rect.get_center().x,viewport_size.x*0.5),context+" art stays horizontally centered")
	check(rect.position.x<=0.01 and rect.end.x>=viewport_size.x-0.01 and rect.end.y>=viewport_size.y-0.01,context+" artwork covers viewport without gaps")
	check(is_equal_approx(rect.size.x/texture_size.x,rect.size.y/texture_size.y),context+" artwork preserves its original aspect ratio")
	check(art.mouse_filter==Control.MOUSE_FILTER_IGNORE,context+" artwork cannot intercept menu touches")

func find_scroll(parent:Node) -> ScrollContainer:
	if parent is ScrollContainer and parent.is_visible_in_tree():return parent
	for child in parent.get_children():
		var found:=find_scroll(child)
		if found:return found
	return null

func drag_touch(start:Vector2,delta:Vector2) -> void:
	touch(start,true);await process_frame
	var point:=start
	for i in range(6):
		var next:=start+delta*float(i+1)/6.0
		var event:=InputEventScreenDrag.new();event.index=0;event.position=next;event.relative=next-point;event.screen_relative=event.relative
		Input.parse_input_event(event);point=next;await process_frame
	touch(point,false);await process_frame;await process_frame

func scroll_pages() -> void:
	# Headless DisplayServer reports a touchscreen only with this fixture flag.
	# The original ScreenTouch/ScreenDrag events still take the full GUI route.
	var emulate_touch_before:=Input.emulate_touch_from_mouse
	Input.emulate_touch_from_mouse=true
	check(DisplayServer.is_touchscreen_available(),"scroll fixture exposes a touchscreen")
	for page in ["garage","map","journal"]:
		main.call("show_"+page);await process_frame;await process_frame
		var scroll:=find_scroll(main.ui)
		check(scroll!=null,"scrolling page exists "+page)
		if scroll==null:continue
		check(scroll.get_v_scroll_bar().max_value>scroll.get_v_scroll_bar().page,"page has scrollable content "+page)
		var body:Control=scroll.get_child(0)
		var card:Control=body.get_child(0)
		# Start on the visible panel's inset instead of its scrollbar or a button.
		var start:=card.global_position+Vector2(4,minf(card.size.y-4,160))
		await drag_touch(start,Vector2(0,-100))
		check(scroll.scroll_vertical>40,"content touch drag scrolls "+page)
		check(main.screen==page,"content drag keeps the same page "+page)
	main.show_map();await process_frame;await process_frame
	var scroll:=find_scroll(main.ui)
	var first:Button=button_named(main.ui,"01  "+main.Incidents.DATA[0][0])
	check(first!=null,"first campaign button found for drag cancellation")
	if first!=null:
		var start:=first.get_global_rect().get_center()+Vector2(0,14)
		await drag_touch(start,Vector2(0,-36))
		check(main.screen=="map","drag ending inside a button does not activate it")
		check(is_instance_valid(scroll) and scroll.scroll_vertical>0,"drag starting on a button scrolls its page")
	# A fresh page removes inertia; an ordinary tap must still start the incident.
	main.show_map();await process_frame;await process_frame
	await tap(button_named(main.ui,"01  "+main.Incidents.DATA[0][0]))
	check(main.screen=="play","ordinary tap inside scrolling page still activates a button")
	main.profile.abandon();main._preview()
	Input.emulate_touch_from_mouse=emulate_touch_before
	main.home();await process_frame;await process_frame

func audio_lifecycle() -> void:
	check(main.music.playback_type==(AudioServer.PLAYBACK_TYPE_STREAM if OS.has_feature("web") else AudioServer.PLAYBACK_TYPE_DEFAULT),"Web music streams; native music retains default backend")
	check(main.spray_audio.playback_type==AudioServer.PLAYBACK_TYPE_DEFAULT,"short effects retain default low-latency backend")
	main._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);main._process(0);await process_frame
	check(main.music.stream_paused,"focus loss pauses music")
	main.fullscreen=true;main._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	for i in range(120):main._process(0)
	await process_frame;check(main.music.stream_paused,"focus return during ad keeps music paused")
	main.fullscreen=false;main._process(0);await process_frame
	check(not main.music.stream_paused,"ad dismissal restores enabled music")
	main.profile.data.music=false;main._music("district_01");await process_frame
	check(main.music.stream_paused,"new district track respects muted setting")
	main._music("menu");await process_frame
	check(main.music.stream_paused,"menu track remains muted across transition")
	main.profile.data.music=true;main._process(0);await process_frame
	check(not main.music.stream_paused and main.music.playing,"music setting resumes the current track")
	for i in range(120):main._process(0)
	await process_frame;check(not main.music.stream_paused and main.music.playing,"unchanged frames preserve playing music")

func run_tests() -> void:
	root.size=Vector2i(540,960)
	var save_path:="user://qa-ui-tests.json"
	var qa_args:=false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--qa-profile=user://qa-"):qa_args=true;save_path=arg.trim_prefix("--qa-profile=")
	if not qa_args:printerr("UI test requires --qa-profile=user://qa-<unique>.json");quit(1);return
	for suffix in ["",".bak",".tmp",".recovery.tmp",".corrupt"]:
		if FileAccess.file_exists(save_path+suffix):DirAccess.remove_absolute(save_path+suffix)
	var scene=load("res://scenes/main.tscn")
	if scene==null or not scene.can_instantiate():printerr("UI game scene failed to load");quit(1);return
	main=scene.instantiate();root.add_child(main);await process_frame;await process_frame;main.set_process(false)
	check(main.screen=="home","initial home");buttons_fit(main.ui);home_art_fits("phone")
	await audio_lifecycle()
	await tap(button_named(main.ui,"Save incident 01"));check(main.screen=="play","native ScreenTouch activates primary Control")
	check(main.home_art==null,"leaving Home clears the artwork reference before later resizes")
	if main.screen!="play":main.start_run("campaign",0);await process_frame
	buttons_fit(main.ui);check(main.run.run_id>0 and not main.profile.data.active.is_empty(),"start snapshot durable")
	var cell:Dictionary=main.run.cells[0];var target:Vector2=main.world.screen_from_world(Vector2(cell.x,cell.z));var contact:=target;var old_heat:float=cell.heat
	touch(contact,true);await process_frame;check(main.dragging and main.pointer_id==0,"ordinary touch begins hose");main._process(0.2);check(main.run.cells[0].heat<old_heat,"touch water cools actual model");check(main.run.water<main.run.capacity,"touch water spends tank")
	touch(contact+Vector2(50,0),true,1);await process_frame;check(main.pointer_id==0,"secondary finger cannot steal hose");touch(contact+Vector2(50,0),false,1);await process_frame
	var drag:=InputEventScreenDrag.new();drag.index=0;drag.position=contact+Vector2(30,0);Input.parse_input_event(drag);await process_frame;check(main.dragging,"ordinary drag keeps spraying")
	touch(contact,false);await process_frame;check(not main.dragging and main.pointer_id==-1,"release clears held input");var old_water:float=main.run.water;main._process(0.2);check(main.run.water>old_water,"release refills")
	await tap(button_named(main.ui,"Pause"));check(main.screen=="pause","touch Pause works");var frozen:float=main.run.elapsed;main._process(0.2);check(main.run.elapsed==frozen,"pause freezes simulation")
	await tap(button_named(main.ui,"Leave incident"));check(main.screen=="leave","leave confirmation visible");await tap(button_named(main.ui,"Back"));check(main.screen=="pause","leave Back preserves accessible Resume")
	await tap(button_named(main.ui,"Resume"));check(main.screen=="play","touch Resume works")
	main._fullscreen_pending("fixture");check(main.screen=="pause" and main.fullscreen,"pending full-screen ad freezes before show");frozen=main.run.elapsed;main._process(0.2);check(main.run.elapsed==frozen,"no background ad simulation");main._fullscreen_changed(false);check(main.screen=="pause","ad dismissal never auto-resumes")
	main._resume();main._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);check(main.screen=="pause" and not main.app_focused,"focus loss pauses");main._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN);check(main.screen=="pause","focus gain requires Resume")
	var saved:Dictionary=main.profile.data.active.duplicate(true);var fresh:=Profile.new(save_path);check(fresh.data.active==JSON.parse_string(JSON.stringify(saved)),"paused run reload exact")
	main.profile.abandon();main._preview();main.home();await process_frame;await process_frame
	for pair in [["Neighborhoods","map"],["Garage","garage"],["Daily","daily"],["Journal","journal"],["Settings","settings"]]:
		await tap(button_named(main.ui,pair[0]));check(main.screen==pair[1],"touch navigation "+pair[1]+" actual="+main.screen);buttons_fit(main.ui);await tap(button_named(main.ui,"Back"));check(main.screen=="home","Back home "+pair[1])
	await scroll_pages()
	main.show_settings();await process_frame;await tap(button_named(main.ui,"Music: On"));check(not main.profile.data.music,"music toggle via touch persists");check(not Profile.new(save_path).data.music,"music toggle saved")
	await tap(button_named(main.ui,"About and licenses"));check(main.screen=="about","about reachable");buttons_fit(main.ui);main.home();await process_frame
	# Actual service-free callback ordering is covered by platform fixtures. Here verify
	# game's state transaction and no pretending that unavailable Web ads earn reward.
	main.start_run("campaign",0)
	for i in range(3000):
		if main.run.done:break
		main.run.advance(1.0/30,Vector2.ZERO,false)
	main._failure();await process_frame
	check(main.screen=="failure" and main.run.done,"failure screen");check(main.reward_button.disabled,"unavailable rewarded button disabled");main._request_recovery();check(not main.run.recovery_used and not main.run.recovery_earned,"unavailable ad gives no reward")
	main.reward_waiting=true;main._fullscreen_pending("rewarded");var failed_time:float=main.run.elapsed;main._reward_earned();check(main.run.done and main.run.recovery_earned,"earned callback persists pending only");main._process(1);check(main.run.elapsed==failed_time,"earned callback does not run gameplay");fresh=Profile.new(save_path);check(fresh.data.active.recovery_earned,"pending earned survives restart")
	main._reward_finished(true);check(main.screen=="pause" and main.run.recovery_used and not main.run.done,"dismissal applies one continuation and pauses");var budget:float=main.run.limit;main._reward_finished(true);main._reward_earned();check(main.run.limit==budget,"repeated callbacks cannot duplicate reward")
	main.profile.abandon();main._preview();main.home();await process_frame
	for size in [Vector2i(720,960),Vector2i(800,1280)]:
		root.size=size;await process_frame;await process_frame;buttons_fit(main.ui);check(main.ui.size.x>=540,"tablet responsive width");home_art_fits("tablet %s"%size)
	# Use the actual Android profile ratios, then return to phone size without
	# rebuilding Home so this exercises its live viewport-resize connection.
	for size in [Vector2i(1200,1920),Vector2i(1600,2560),Vector2i(540,960)]:
		root.size=size;await process_frame;await process_frame;home_art_fits("live resize %s"%size)
	# Release the fixture's active streams and let the audio mix thread retire
	# their playbacks before the headless SceneTree exits.
	main.music.stop();main.music.stream=null;main.spray_audio.stop();main.spray_audio.stream=null
	for player in main.sounds:player.stop();player.stream=null
	await create_timer(0.1).timeout
	main.queue_free();await process_frame;main=null;await process_frame
	if failures.is_empty():print("UI PASS checks=%d"%checks);call_deferred("quit",0)
	else:printerr("UI FAILED %d / %d"%[failures.size(),checks]);call_deferred("quit",1)
