extends Node3D
const Run=preload("res://game/run.gd")
const Profile=preload("res://game/profile.gd")
const Incidents=preload("res://game/incidents.gd")
const Upgrades=preload("res://game/upgrades.gd")
const World=preload("res://game/world.gd")
const INK:=Color("143d43")
const CREAM:=Color("fff4d9")
const GOLD:=Color("ffd27b")
const MUTED:=Color("b4d0cb")
const AQUA:=Color("66d9dc")
var profile:RefCounted
var run:RefCounted
var world:Node3D
var ui:Control
var service:Node
var catalog:Dictionary={}
var audio_manifest:Dictionary={}
var screen:="home"
var aim:=Vector2.ZERO
var dragging:=false
var pointer_id:=-1
var touch_offset:=0.0
var fullscreen:=false
var app_focused:=true
var reward_waiting:=false
var pending_action:Dictionary={}
var receipt:Dictionary={}
var checkpoint_time:=0.0
var clear_hold:=0.0
var toast_time:=0.0
var toast_label:Label
var hud_water:ProgressBar
var hud_integrity:ProgressBar
var hud_time:Label
var hud_count:Label
var hud_hint:Label
var hud_water_text:Label
var hud_ember:Label
var reward_button:Button
var reward_hint:Label
var banner_spacer:Control
var music:AudioStreamPlayer
var spray_audio:AudioStreamPlayer
var sounds:Array[AudioStreamPlayer]=[]
var music_key:=""
var result_panel:Control
var result_elapsed:=0.0
var starting:=false

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	var save_path:="user://cinderbrook-v1.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--qa-profile=user://qa-"):save_path=arg.trim_prefix("--qa-profile=")
	profile=Profile.new(save_path)
	catalog=JSON.parse_string(FileAccess.get_file_as_string("res://game/catalog.json"))
	if FileAccess.file_exists("res://assets/audio/manifest.json"):audio_manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/manifest.json"))
	music=AudioStreamPlayer.new();music.volume_db=-15;add_child(music)
	spray_audio=AudioStreamPlayer.new();spray_audio.volume_db=-18;add_child(spray_audio)
	for i in range(8):
		var player:=AudioStreamPlayer.new();player.volume_db=-8;add_child(player);sounds.append(player)
	world=World.new();add_child(world)
	var layer:=CanvasLayer.new();add_child(layer)
	ui=Control.new();ui.name="Interface";ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(ui)
	var theme:=Theme.new();theme.default_font_size=20;theme.set_color("font_color","Label",CREAM);theme.set_color("font_color","Button",INK);theme.set_color("font_disabled_color","Button",Color("8da3a1"))
	theme.set_stylebox("normal","Button",button_style(GOLD));theme.set_stylebox("hover","Button",button_style(Color("ffe7ac")));theme.set_stylebox("pressed","Button",button_style(Color("d3a35c"),true));theme.set_stylebox("disabled","Button",button_style(Color("426166")))
	ui.theme=theme
	service=get_node_or_null("/root/Services")
	if service:
		service.configure_catalog(catalog);service.fullscreen_pending.connect(_fullscreen_pending);service.fullscreen_visibility_changed.connect(_fullscreen_changed);service.reward_earned.connect(_reward_earned);service.reward_finished.connect(_reward_finished);service.interstitial_finished.connect(_interstitial_finished);service.menu_bottom_reserve_changed.connect(_reserve_changed);service.services_updated.connect(_services_updated);service.service_notice.connect(_service_notice)
		fullscreen=service.fullscreen_ad_active()
	var gift:int=profile.login(Profile.today());_sync_metrics()
	if not profile.data.active.is_empty():
		run=Run.restore(profile.data.active)
		if run.recovery_earned:
			run.apply_recovery()
			if not profile.store_run(run.snapshot()):toast(profile.last_error)
		world.build(run);_pause("Your crew is ready. Resume when you are.")
	else:_preview();home()
	if gift>0:toast("Day %d gift: +%d supplies"%[profile.data.streak,gift])
	if not profile.recovery.is_empty():toast(profile.recovery)
	get_viewport().size_changed.connect(_resized)

func style(color:Color,radius:int=18) -> StyleBoxFlat:
	var b:=StyleBoxFlat.new();b.bg_color=color;b.corner_radius_top_left=radius;b.corner_radius_top_right=radius;b.corner_radius_bottom_left=radius;b.corner_radius_bottom_right=radius;b.content_margin_left=18;b.content_margin_right=18;b.content_margin_top=14;b.content_margin_bottom=14;return b

func button_style(color:Color,pressed:bool=false) -> StyleBoxTexture:
	var b:=StyleBoxTexture.new();b.texture=load("res://assets/ui/button_pressed.png" if pressed else "res://assets/ui/button.png");b.modulate_color=color
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:b.set_texture_margin(side,12);b.set_content_margin(side,12)
	return b

func label(text:String,size:int=20,color:Color=CREAM) -> Label:
	var l:=Label.new();l.text=text;l.add_theme_font_size_override("font_size",size);l.add_theme_color_override("font_color",color);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.mouse_filter=Control.MOUSE_FILTER_IGNORE;return l

func button(text:String,callback:Callable,muted:bool=false) -> Button:
	var b:=Button.new();b.text=text;b.custom_minimum_size.y=56;b.add_theme_font_size_override("font_size",20);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	if muted:b.add_theme_stylebox_override("normal",button_style(Color("355c62")));b.add_theme_stylebox_override("hover",button_style(Color("48777b")));b.add_theme_color_override("font_color",CREAM)
	b.pressed.connect(func():
		if fullscreen:return
		sound("tap");callback.call()
	);return b

func _clear_ui() -> void:
	_clear_pointer()
	for child in ui.get_children():
		if child is CanvasItem:child.hide()
		child.queue_free()
	hud_water=null;hud_integrity=null;hud_time=null;hud_count=null;hud_hint=null;hud_water_text=null;hud_ember=null;reward_button=null;reward_hint=null;banner_spacer=null;toast_label=null;result_panel=null

func _margin(parent:Control,preset:int,top:float,bottom:float) -> VBoxContainer:
	var m:=MarginContainer.new();m.set_anchors_and_offsets_preset(preset);m.offset_left=24;m.offset_right=-24;m.offset_top=top;m.offset_bottom=bottom;parent.add_child(m)
	var v:=VBoxContainer.new();v.add_theme_constant_override("separation",10);m.add_child(v);return v

func _panel(parent:Control) -> VBoxContainer:
	var p:=PanelContainer.new();var box:=style(Color(0.035,0.12,0.14,0.96));box.border_width_bottom=2;box.border_color=Color("568b88");p.add_theme_stylebox_override("panel",box);parent.add_child(p)
	var v:=VBoxContainer.new();v.add_theme_constant_override("separation",10);p.add_child(v);return v

func _row(parent:Control) -> HBoxContainer:
	var r:=HBoxContainer.new();r.add_theme_constant_override("separation",10);parent.add_child(r);return r

func _spacer(parent:Control,height:float) -> Control:
	var c:=Control.new();c.custom_minimum_size.y=height;parent.add_child(c);return c

func _state(value:String) -> void:
	screen=value;_clear_ui()
	if service:service.set_banner_visible(value in ["home","result"])
	_music("district_%02d"%(int(run.spec.theme)+1) if value in ["play","pause","failure","wave","result"] else "menu")

func _preview() -> void:
	run=Run.new();run.start(0,"campaign",profile.frontier(),profile.data.gear,Profile.today());world.build(run)

func home() -> void:
	_refresh_day();_state("home")
	var splash:=TextureRect.new();splash.texture=load("res://assets/brand/splash-portrait.png");splash.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;splash.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;splash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);splash.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.add_child(splash)
	var bottom:=_margin(ui,Control.PRESET_BOTTOM_WIDE,-410-_reserve(),-18)
	var card:=_panel(bottom);var head:=_row(card);var rank:=label("BRIGADE RANK %d"%profile.level(),16,AQUA);rank.autowrap_mode=TextServer.AUTOWRAP_OFF;rank.size_flags_horizontal=Control.SIZE_EXPAND_FILL;head.add_child(rank);var wallet:=label("%d supplies"%profile.data.coins,18,GOLD);wallet.autowrap_mode=TextServer.AUTOWRAP_OFF;head.add_child(wallet)
	card.add_child(button("Save incident %02d"%(profile.frontier()+1),func():_transition("campaign",profile.frontier())))
	var row:=_row(card);row.add_child(button("Neighborhoods",show_map,true));row.add_child(button("Garage",show_garage,true))
	row=_row(card);row.add_child(button("Daily",show_daily,true));row.add_child(button("Endless Watch",func():_transition("endless",0),true))
	row=_row(card);row.add_child(button("Journal",show_journal,true));row.add_child(button("Settings",show_settings,true))
	card.add_child(label("HOLD TO SPRAY  /  LIFT TO REFILL",14,MUTED))
	banner_spacer=_spacer(bottom,_reserve())

func _page(title:String,subtitle:String="") -> VBoxContainer:
	var shade:=ColorRect.new();shade.color=Color(0.025,0.08,0.10,0.92);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.add_child(shade)
	var outer:=_margin(ui,Control.PRESET_FULL_RECT,22,-20)
	var top:=_row(outer);var heading:=label(title,30,GOLD);heading.autowrap_mode=TextServer.AUTOWRAP_OFF;heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top.add_child(heading)
	var back:=button("Back",func():
		if screen=="leave":_pause()
		else:home()
	,true);back.custom_minimum_size=Vector2(90,48);back.size_flags_horizontal=0;top.add_child(back)
	if not subtitle.is_empty():outer.add_child(label(subtitle,17,MUTED))
	var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;outer.add_child(scroll)
	var body:=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",12);scroll.add_child(body);return body

func show_map() -> void:
	_state("map");var body:=_page("Neighborhoods","36 handcrafted incidents. Earn stars by protecting the town.")
	var frontier:int=profile.frontier()
	for district in range(6):
		var card:=_panel(body);card.add_child(label(Incidents.THEMES[district],24,GOLD))
		var grid:=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",10);card.add_child(grid)
		for i in range(district*6,district*6+6):
			var cell:=VBoxContainer.new();cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_child(cell)
			var index:=i;var b:=button("%02d  %s"%[i+1,Incidents.DATA[i][0]],func():_transition("campaign",index),i>frontier);b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;b.custom_minimum_size.y=74;b.disabled=i>frontier;b.add_theme_font_size_override("font_size",17);cell.add_child(b)
			_stars(cell,int(profile.data.stars[i]) if i<profile.data.stars.size() else 0,22)

func show_garage() -> void:
	_state("garage");var body:=_page("Brigade garage","%d supplies  |  Rank %d  |  %d XP"%[profile.data.coins,profile.level(),profile.data.xp])
	for key in Upgrades.KEYS:
		var card:=_panel(body);var rank:=int(profile.data.gear[key]);card.add_child(label(Upgrades.NAMES[key],24,GOLD));card.add_child(label(Upgrades.DETAILS[key],18));card.add_child(label("Rank %d / 4   -   %s"%[rank,Upgrades.effect(key,rank)],18,AQUA))
		var upgrade_key:String=key
		var b:=button("Fully upgraded" if rank>=4 else "Upgrade - %d supplies"%Upgrades.price(key,rank),func():
			if profile.purchase(upgrade_key):sound("upgrade");_sync_metrics();show_garage();toast("Crew equipment upgraded")
			else:toast(profile.last_error if not profile.last_error.is_empty() else "More supplies needed")
		)
		b.disabled=rank>=4 or int(profile.data.coins)<Upgrades.price(key,rank);card.add_child(b)
	body.add_child(label("Every campaign incident is beatable with base equipment. Upgrades give your crew extra comfort.",17,MUTED))

func show_daily() -> void:
	_refresh_day();_state("daily");var body:=_page("Daily dispatch","A little reason to come back. Login gifts follow your local device's UTC date.")
	var login:=_panel(body);login.add_child(label("Day %d of 7 claimed"%profile.data.streak,24,GOLD));var days:=GridContainer.new();days.columns=7;days.add_theme_constant_override("h_separation",5);login.add_child(days)
	for day in range(1,8):
		var cell:=VBoxContainer.new();cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL;days.add_child(cell);cell.add_child(label("%d"%day,17,AQUA if day<=profile.data.streak else MUTED));cell.add_child(label("+%d"%Profile.login_reward(day),14,GOLD))
	login.add_child(label("Consecutive visits build to +95 supplies on day seven. Your gift is already safely collected.",17))
	var daily:=_panel(body);var spec:Dictionary=Incidents.make(0,"daily",Profile.today());daily.add_child(label("Today's incident: "+spec.name,22,GOLD));daily.add_child(label("A seeded variation of an authored scene. First clear today: +70 supplies and +100 XP.",17));daily.add_child(button("Play Daily Incident",func():_transition("daily",0)))
	for key in Profile.QUESTS:
		var card:=_panel(body);var quest:Dictionary=Profile.QUESTS[key];var count:=mini(int(profile.data.quest[key]),int(quest.target));card.add_child(label(quest.title,22));card.add_child(label("%d / %d   -   +35 supplies, +50 XP"%[count,quest.target],17,AQUA))
		var quest_key:String=key;var claimed:bool=key in profile.data.quest_claims
		var b:=button("Claimed" if claimed else "Claim reward",func():
			if profile.claim_quest(quest_key,Profile.today()):sound("confirm");_sync_metrics();show_daily()
		);b.disabled=claimed or count<int(quest.target);card.add_child(b)

func show_journal() -> void:
	_state("journal");var body:=_page("Brigade journal","Your records and achievements are always available offline.")
	var records:=_panel(body);records.add_child(label("Your local records",24,GOLD));var stats:Dictionary=profile.metrics()
	for board in catalog.leaderboards:
		var row:=_row(records);_icon(row,board.icon,42);var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(column);column.add_child(label(board.name,19));column.add_child(label(str(stats.get(board.metric,0)),24,AQUA))
	if service:
		var row:=_row(records);row.add_child(button("Play Games",func():service.request_sign_in(),true));row.add_child(button("Online boards",func():service.open_leaderboards(),true))
	for item in catalog.achievements:
		var card:=_panel(body);var row:=_row(card);_icon(row,item.icon,64);var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(column)
		var unlocked:bool=profile.data.achievements.get(item.id,false);column.add_child(label(item.name,21,GOLD if unlocked else CREAM));column.add_child(label(item.description,16,MUTED));column.add_child(label("Earned" if unlocked else "%d / %d"%[mini(int(stats.get(item.metric,0)),int(item.threshold)),item.threshold],16,AQUA))

func show_settings() -> void:
	_state("settings");var body:=_page("Settings","Make the brigade feel comfortable in your hands.")
	var options:Dictionary={"music":"Music","sfx":"Sound effects","motion":"Animated effects","vibration":"Haptic feedback"}
	for key in options:
		var option_key:String=key;var b:=button(options[key]+": "+("On" if profile.data[key] else "Off"),func():
			if profile.setting(option_key,not profile.data[option_key]):show_settings()
		);body.add_child(b)
	var card:=_panel(body);card.add_child(label("Privacy and services",24,GOLD));card.add_child(label("Optional ads can help your crew continue. They never run during active play. Your local progress stays on this device.",18))
	if service:
		card.add_child(button("Privacy choices",func():service.request_privacy_options(),true));card.add_child(button("Connect Play Games",func():service.request_sign_in(),true))
		card.add_child(label(service.status(),16,MUTED))
	body.add_child(button("About and licenses",show_about,true))

func show_about() -> void:
	_state("about");var body:=_page("About Cinderbrook","One finger. A whole neighborhood worth saving.")
	var card:=_panel(body);card.add_child(label("A small town, a steady crew",25,GOLD));card.add_child(label("Sweep water over the glowing objects, lift to refill, and keep the neighborhood safe. Gold rings warn of incoming embers. Wet targets can prevent them from taking hold. This is a whimsical arcade game, not firefighting training.",19))
	card.add_child(label("Original game: Apache License 2.0. Kenney model, UI and icon assets retain their CC0 licenses. Original commissioned artwork and audio are included with the project. Plugin license notices are retained in LICENSES and their addon folders.",17,MUTED))
	card.add_child(label("Godot 4.5.1 Compatibility. Campaign: 36 authored incidents, six neighborhoods. Daily variants and Endless Watch use the same fair fire model. No purchase is required to complete the campaign.",17))

func _icon(parent:Control,path:String,size_px:int) -> void:
	var icon:=TextureRect.new();icon.texture=load(path) if ResourceLoader.exists(path) else null;icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.custom_minimum_size=Vector2(size_px,size_px);icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(icon)

func _stars(parent:Control,count:int,size_px:int=52) -> void:
	var row:=HBoxContainer.new();row.alignment=BoxContainer.ALIGNMENT_CENTER;row.add_theme_constant_override("separation",8);parent.add_child(row)
	for i in range(3):_icon(row,"res://assets/ui/star_full.png" if i<count else "res://assets/ui/star_empty.png",size_px)

func start_run(kind:String,index:int) -> void:
	if starting or fullscreen:return
	starting=true;var id:int=profile.new_run()
	if id==0:starting=false;toast(profile.last_error);return
	run=Run.new();run.start(id,kind,index,profile.data.gear,Profile.today())
	if not profile.store_run(run.snapshot()):starting=false;toast(profile.last_error);return
	receipt={};reward_waiting=false;clear_hold=0;checkpoint_time=0;aim=Vector2.ZERO;world.build(run);starting=false;_play_ui()

func _bar(parent:Control,color:Color,height:int=13) -> ProgressBar:
	var b:=ProgressBar.new();b.max_value=100;b.show_percentage=false;b.custom_minimum_size.y=height;b.add_theme_stylebox_override("background",style(Color("264b53"),6));b.add_theme_stylebox_override("fill",style(color,6));parent.add_child(b);return b

func _play_ui() -> void:
	_state("play")
	var top:=_margin(ui,Control.PRESET_TOP_WIDE,18,175);var head:=_row(top)
	var title:=label("WATCH %d"%run.wave if run.mode=="endless" else "DAILY INCIDENT" if run.mode=="daily" else "INCIDENT %02d"%(run.incident+1),16,GOLD);title.autowrap_mode=TextServer.AUTOWRAP_OFF;title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;head.add_child(title)
	var pause:=button("Pause",func():_pause(),true);pause.custom_minimum_size=Vector2(94,44);pause.size_flags_horizontal=0;head.add_child(pause)
	var panel:=_panel(top);var row:=_row(panel);hud_count=label("",20);hud_count.autowrap_mode=TextServer.AUTOWRAP_OFF;hud_count.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(hud_count);hud_time=label("",22,GOLD);hud_time.autowrap_mode=TextServer.AUTOWRAP_OFF;row.add_child(hud_time);hud_integrity=_bar(panel,Color("a8d89b"),10);hud_ember=label(run.spec.name,16,MUTED);panel.add_child(hud_ember)
	var bottom:=_margin(ui,Control.PRESET_BOTTOM_WIDE,-174,-20);var card:=_panel(bottom);hud_water_text=label("",20,AQUA);card.add_child(hud_water_text);hud_water=_bar(card,AQUA,17);hud_hint=label("HOLD TO SPRAY  /  LIFT TO REFILL",17);hud_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;card.add_child(hud_hint)
	_update_hud()

func _update_hud() -> void:
	if not is_instance_valid(hud_water):return
	hud_water.max_value=run.capacity;hud_water.value=run.water;hud_integrity.value=run.integrity();hud_count.text="%d fires  |  %d%% safe"%[run.burning(),int(run.integrity())];hud_time.text="%ds"%int(ceil(maxf(0,run.limit-run.elapsed)))
	hud_water_text.text="WATER %d / %d"%[int(ceil(run.water)),int(run.capacity)]
	if run.done:hud_hint.text="NEIGHBORHOOD SAFE" if run.won else "CREW RETURNING"
	elif dragging and run.water<1:hud_hint.text="LIFT YOUR FINGER TO REFILL"
	elif not dragging and run.water<run.capacity-1:hud_hint.text="REFILLING...  HOLD WHEN YOU'RE READY"
	elif run.incident<3 and run.mode=="campaign":hud_hint.text="HOLD ON A GLOWING OBJECT. LIFT TO REFILL."
	else:hud_hint.text="HOLD TO SPRAY  /  LIFT TO REFILL"
	var ember:Dictionary=run.next_ember()
	if not ember.is_empty() and float(ember["in"])<=4:hud_ember.text="EMBER IN %ds - WET THE GOLD RING"%int(ceil(ember["in"]));hud_ember.add_theme_color_override("font_color",GOLD)
	elif run.burning()==0 and not ember.is_empty():hud_ember.text="Stay ready - next ember in %ds"%int(ceil(ember["in"]))
	else:hud_ember.text=run.spec.name;hud_ember.add_theme_color_override("font_color",MUTED)

func _input(event:InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:_back();get_viewport().set_input_as_handled()
	if event is InputEventScreenTouch and not event.pressed and event.index==pointer_id:_clear_pointer()
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed and pointer_id==-2:_clear_pointer()

func _unhandled_input(event:InputEvent) -> void:
	if screen!="play" or fullscreen or not app_focused or run.done:return
	# Controls use Godot's emulated mouse for touch. The hose listens to the
	# original touch only, otherwise the emulated press steals its pointer ID.
	if event is InputEventMouse and event.device==-1:return
	if event is InputEventScreenTouch and event.pressed and pointer_id==-1:_aim_begin(event.position,event.index,true)
	elif event is InputEventScreenDrag and event.index==pointer_id:_aim_to(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and pointer_id==-1:_aim_begin(event.position,-2,false)
	elif event is InputEventMouseMotion and pointer_id==-2:_aim_to(event.position)

func _aim_begin(pos:Vector2,id:int,touch:bool) -> void:
	if pos.y<190 or pos.y>ui.size.y-190:return
	# Visible roof hit targets and the large spray-ring edge remain readable
	# around a finger. Direct targeting is more intuitive than an invisible offset.
	pointer_id=id;touch_offset=0.0;dragging=true;_aim_to(pos)

func _aim_to(pos:Vector2) -> void:
	aim=world.world_from_screen(pos-Vector2(0,touch_offset))

func _clear_pointer() -> void:
	dragging=false;pointer_id=-1;touch_offset=0
	if is_instance_valid(spray_audio):spray_audio.stop()

func _process(delta:float) -> void:
	if run==null or ui==null:return
	if toast_time>0:
		toast_time=maxf(0,toast_time-delta)
		if is_instance_valid(toast_label):toast_label.visible=toast_time>0
	if music:music.stream_paused=not profile.data.music or fullscreen or not app_focused
	if screen=="play" and not fullscreen and app_focused:
		if not run.done:
			var old_doused:int=run.doused;var old_water:float=run.water;run.advance(delta,aim,dragging)
			if run.doused>old_doused:sound("extinguish");_haptic(22)
			if not dragging and old_water<run.capacity and run.water>=run.capacity:sound("refill")
			_spray_sound(run.spraying)
			checkpoint_time+=delta
			if checkpoint_time>=1.0:
				checkpoint_time=0
				if not profile.store_run(run.snapshot()):_pause(profile.last_error)
			if run.done:
				_clear_pointer();clear_hold=0.75 if run.won else 0.35
				if not profile.store_run(run.snapshot()):_pause(profile.last_error)
		else:
			clear_hold-=delta
			if clear_hold<=0:
				if run.won:_complete_success()
				else:_failure()
		_update_hud()
	world.update_view(run,aim,screen=="play" and dragging and run.spraying and not run.done and not fullscreen and app_focused,delta if profile.data.motion and app_focused and not fullscreen else 0.0)
	if is_instance_valid(result_panel):
		result_elapsed=minf(1,result_elapsed+delta/0.25);result_panel.modulate.a=result_elapsed

func _pause(message:String="Take a breath. Your neighborhood is paused.") -> void:
	_clear_pointer()
	if run.run_id>0 and run.run_id>int(profile.data.last_paid_run):
		if not profile.store_run(run.snapshot()):message=profile.last_error
	_state("pause");var outer:=_margin(ui,Control.PRESET_CENTER, -160,170);outer.get_parent().offset_left=-230;outer.get_parent().offset_right=230
	var card:=_panel(outer);card.add_child(label("Crew on standby",29,GOLD));card.add_child(label(message,19));card.add_child(button("Resume",_resume));card.add_child(button("Leave incident",_confirm_leave,true))

func _resume() -> void:
	if fullscreen or not app_focused:return
	if not profile.store_run(run.snapshot()):toast(profile.last_error);return
	if run.done:
		if run.won:_complete_success()
		else:_failure()
	else:_play_ui()

func _confirm_leave() -> void:
	_state("leave");var body:=_page("Leave this incident?","Your crew can try again whenever you are ready.")
	var card:=_panel(body);card.add_child(label("Leaving a live incident gives no supplies or XP. Completed Endless waves can be banked after the wave ends.",20));card.add_child(button("Keep playing",func():_pause()))
	card.add_child(button("Leave and return home",func():
		if profile.abandon():_preview();home()
		else:toast(profile.last_error)
	,true))

func _complete_success() -> void:
	sound("win");_haptic(50)
	if run.mode=="endless":_wave_result()
	else:_settle_and_result()

func _wave_result() -> void:
	_state("wave");var bottom:=_margin(ui,Control.PRESET_BOTTOM_WIDE,-390,-20);var card:=_panel(bottom);card.add_child(label("Watch %d safe!"%run.wave,30,GOLD));_stars(card,run.stars());card.add_child(label("%d points  /  %d hotspots cooled"%[run.score,run.doused],20,AQUA))
	card.add_child(button("Continue the watch",func():
		var before:Dictionary=run.snapshot()
		if run.next_wave() and profile.store_run(run.snapshot()):world.build(run);_play_ui()
		else:run=Run.restore(before);toast(profile.last_error)
	));card.add_child(button("Bank the watch",_settle_and_result,true))

func _failure() -> void:
	_state("failure");sound("lose");var bottom:=_margin(ui,Control.PRESET_BOTTOM_WIDE,-420,-20);var card:=_panel(bottom);card.add_child(label("A fresh start awaits",29,GOLD));card.add_child(label(run.failure,19));card.add_child(label("%d hotspots cooled. Your crew is safe."%run.doused,18,AQUA))
	if not run.recovery_used:
		reward_button=button("Watch ad - emergency refill",_request_recovery);card.add_child(reward_button);reward_hint=label("",16,MUTED);card.add_child(reward_hint);_services_updated()
	else:card.add_child(label("The emergency refill has been used for this incident.",17,MUTED))
	card.add_child(button("End incident",_settle_and_result,true))

func _settle_and_result() -> void:
	var first:bool=run.run_id>int(profile.data.last_paid_run)
	if first:
		receipt=profile.settle(run,Profile.today())
		if receipt.is_empty():_pause(profile.last_error);return
		_sync_metrics()
		if service and run.sprayed_seconds>=0.1:service.record_round_completed("incident-%d"%run.run_id)
	else:receipt=profile.data.last_receipt
	_result()

func _result() -> void:
	_state("result");var bottom:=_margin(ui,Control.PRESET_BOTTOM_WIDE,-430-_reserve(),-18);var card:=_panel(bottom);result_panel=card.get_parent();result_panel.modulate.a=0;result_elapsed=0
	card.add_child(label("Neighborhood safe!" if run.won else "Ready for another try?",29,GOLD));_stars(card,run.stars())
	card.add_child(label("%d%% structure  /  %ds remaining"%[int(run.integrity()),int(maxf(0,run.limit-run.elapsed))],18,AQUA));card.add_child(label("+%d supplies   +%d XP   %d points"%[receipt.get("coins",0),receipt.get("xp",0),run.score],20))
	card.add_child(label("Three stars: 80% structure and 20% time remaining.",15,MUTED))
	if run.mode=="campaign" and run.won and run.incident<35:card.add_child(button("Next incident",func():_transition("campaign",run.incident+1)))
	else:card.add_child(button("Play again",func():_transition(run.mode,run.incident)))
	var row:=_row(card);row.add_child(button("Replay",func():_transition(run.mode,run.incident),true));row.add_child(button("Home",func():_preview();home(),true));banner_spacer=_spacer(bottom,_reserve())

func _transition(kind:String,index:int) -> void:
	if not pending_action.is_empty() or fullscreen:return
	pending_action={"kind":kind,"index":index}
	if service and service.request_interstitial_at_transition():return
	_launch_pending(false)

func _launch_pending(pause_after:bool) -> void:
	if pending_action.is_empty():return
	var next:=pending_action.duplicate();pending_action={};start_run(next.kind,next.index)
	if pause_after and screen=="play":_pause("Ready for the next incident. Tap Resume to begin.")

func _request_recovery() -> void:
	if reward_waiting or run==null or not run.done or run.won or run.recovery_used:return
	reward_waiting=true
	if not service or not service.request_rewarded_continue():reward_waiting=false;toast("No rescue ad is available right now.");_services_updated()

func _reward_earned() -> void:
	if not reward_waiting or run==null:return
	if run.mark_recovery_earned():
		if not profile.store_run(run.snapshot()):toast(profile.last_error)

func _reward_finished(earned:bool) -> void:
	if not reward_waiting:return
	reward_waiting=false;fullscreen=false;_clear_pointer()
	if earned and run.recovery_earned:
		run.apply_recovery()
		if not profile.store_run(run.snapshot()):_pause(profile.last_error);return
		_pause("Emergency refill ready: +30 seconds, water and repaired structure. Tap Resume.")
	else:
		run.recovery_earned=false;profile.store_run(run.snapshot());_failure();toast("No continuation earned. You can try again.")

func _fullscreen_pending(_reason:String) -> void:
	fullscreen=true;_clear_pointer()
	if screen=="play":_pause("Your incident is paused. Resume after returning.")
	elif run!=null and run.run_id>int(profile.data.last_paid_run):profile.store_run(run.snapshot())

func _fullscreen_changed(value:bool) -> void:
	fullscreen=value;_clear_pointer()
	if value and screen=="play":_pause("Your crew is waiting. Resume after returning.")

func _interstitial_finished(shown:bool) -> void:
	fullscreen=false
	if not pending_action.is_empty():_launch_pending(shown)

func _services_updated() -> void:
	if is_instance_valid(reward_button):reward_button.disabled=reward_waiting or not service or not service.can_reward()
	if is_instance_valid(reward_hint):reward_hint.text="Optional: earn +30 seconds, 80% water and +35 structure per object. One per incident." if service and service.can_reward() else "Rescue ads are unavailable right now. You can still end the incident and retry."

func _service_notice(message:String) -> void:
	if screen in ["settings","journal"]:toast(message)

func _sync_metrics() -> void:
	profile.update_achievements(catalog)
	if service:service.submit_metrics(profile.metrics())

func _refresh_day() -> void:
	var gift:int=profile.login(Profile.today())
	if gift>0:_sync_metrics()

func _reserve() -> float:return service.menu_bottom_reserve(ui) if service else 0.0
func _reserve_changed() -> void:
	if is_instance_valid(banner_spacer):banner_spacer.custom_minimum_size.y=_reserve()
	if screen in ["home","result"]:call_deferred("home" if screen=="home" else "_result")

func _resized() -> void:_clear_pointer()

func _back() -> void:
	if fullscreen:return
	if screen=="play":_pause()
	elif screen=="pause":_resume()
	elif screen in ["failure","wave","leave"]:_pause()
	elif screen!="home":home()

func _notification(what:int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:
		app_focused=false;_clear_pointer()
		if run!=null and screen=="play":_pause("Your incident was paused while you were away.")
	elif what in [NOTIFICATION_APPLICATION_FOCUS_IN,NOTIFICATION_APPLICATION_RESUMED]:app_focused=true
	elif what==NOTIFICATION_WM_GO_BACK_REQUEST and is_instance_valid(ui):_back()
	elif what==NOTIFICATION_WM_CLOSE_REQUEST and run!=null:
		if run.run_id>int(profile.data.last_paid_run):profile.store_run(run.snapshot())

func toast(message:String) -> void:
	if ui==null:return
	if not is_instance_valid(toast_label):
		toast_label=label(message,18,CREAM);toast_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE);toast_label.offset_left=35;toast_label.offset_right=-35;toast_label.offset_top=185;toast_label.offset_bottom=250;toast_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;toast_label.add_theme_stylebox_override("normal",style(Color(0.03,0.10,0.13,0.96),10));ui.add_child(toast_label)
	toast_label.text=message;toast_label.show();toast_time=3.5

func _music(key:String) -> void:
	if music_key==key:return
	music_key=key;var path:String=audio_manifest.get("music",{}).get(key,"")
	if path.is_empty() or not ResourceLoader.exists(path):music.stop();return
	music.stream=load(path)
	if music.stream is AudioStreamWAV:
		music.stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;music.stream.loop_begin=0;music.stream.loop_end=int(music.stream.get_length()*music.stream.mix_rate)
	music.play()
	music.stream_paused=not profile.data.music or fullscreen or not app_focused

func sound(key:String) -> void:
	if profile==null or not profile.data.sfx or not app_focused or fullscreen:return
	var path:String=audio_manifest.get("sfx",{}).get(key,"")
	if path.is_empty() or not ResourceLoader.exists(path):return
	for player in sounds:
		if not player.playing:player.stream=load(path);player.play();return

func _spray_sound(active:bool) -> void:
	if not active or not profile.data.sfx or fullscreen or not app_focused:spray_audio.stop();return
	if spray_audio.playing:return
	var path:String=audio_manifest.get("sfx",{}).get("water","")
	if not path.is_empty() and ResourceLoader.exists(path):spray_audio.stream=load(path);spray_audio.play()

func _haptic(ms:int) -> void:
	if profile.data.vibration and OS.get_name()=="Android":Input.vibrate_handheld(ms)
