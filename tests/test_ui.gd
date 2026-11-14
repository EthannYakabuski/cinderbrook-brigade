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
	check(main.screen=="home","initial home");buttons_fit(main.ui)
	await tap(button_named(main.ui,"Save incident 01"));check(main.screen=="play","native ScreenTouch activates primary Control")
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
		root.size=size;await process_frame;await process_frame;buttons_fit(main.ui);check(main.ui.size.x>=540,"tablet responsive width")
	main.queue_free();await process_frame;main=null;await process_frame
	if failures.is_empty():print("UI PASS checks=%d"%checks);call_deferred("quit",0)
	else:printerr("UI FAILED %d / %d"%[failures.size(),checks]);call_deferred("quit",1)
