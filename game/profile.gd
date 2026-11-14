extends RefCounted
const Run=preload("res://game/run.gd")
const Upgrades=preload("res://game/upgrades.gd")
const QUESTS := {"doused":{"title":"Cool 20 hotspots","target":20},"clears":{"title":"Clear 3 incidents","target":3},"prevented":{"title":"Prevent 2 ember landings","target":2}}
var path:="user://cinderbrook-v1.json"
var data:Dictionary={}
var recovery:=""
var last_error:=""
var recovery_source:=""

func _init(save_path:String="user://cinderbrook-v1.json") -> void:
	path=save_path;data=defaults();load_profile()

static func defaults() -> Dictionary:
	return {"version":1,"sequence":0,"xp":0,"coins":0,"gear":Upgrades.normalize({}),"stars":[],"next_run":1,"last_paid_run":0,"active":{},"totals":{"rounds":0,"clears":0,"doused":0,"prevented":0,"perfect":0,"daily_clears":0},"records":{"best_score":0,"endless_wave":0,"best_integrity":0,"best_streak":0},"login_day":-1,"streak":0,"quest_day":-1,"quest":{"doused":0,"clears":0,"prevented":0},"quest_claims":[],"daily_paid":-1,"achievements":{},"music":true,"sfx":true,"motion":true,"vibration":true,"last_receipt":{}}

static func today() -> int:return int(Time.get_unix_time_from_system()/86400.0)
static func login_reward(streak:int) -> int:return 25+10*clampi(streak,1,7)

static func valid(v:Variant) -> bool:
	if not v is Dictionary:return false
	for key in defaults():
		if not v.has(key):return false
	if v.version!=1:return false
	for key in ["sequence","xp","coins","next_run","last_paid_run","streak"]:
		if not Run.integer(v[key],0,1e12):return false
	if v.streak>7 or v.next_run<1 or v.last_paid_run>=v.next_run:return false
	for key in ["login_day","quest_day","daily_paid"]:
		if not Run.integer(v[key],-1,1e9):return false
	for key in ["music","sfx","motion","vibration"]:
		if not v[key] is bool:return false
	for key in ["gear","active","totals","records","quest","achievements","last_receipt"]:
		if not v[key] is Dictionary:return false
	for key in Upgrades.KEYS:
		if not Run.integer(v.gear.get(key),0,4):return false
	if not v.active.is_empty():
		if not Run.valid_snapshot(v.active):return false
		if int(v.active.run_id)<=int(v.last_paid_run) or int(v.active.run_id)!=int(v.next_run)-1:return false
	for section in ["totals","records","quest"]:
		for key in defaults()[section]:
			if not Run.integer(v[section].get(key),0,1e12):return false
	if not v.stars is Array or v.stars.size()>36 or not v.quest_claims is Array or v.quest_claims.size()>3:return false
	for n in v.stars:
		if not Run.integer(n,0,3):return false
	for key in v.quest_claims:
		if key not in QUESTS:return false
	for key in v.achievements:
		if not key is String or not v.achievements[key] is bool:return false
	if not v.last_receipt.is_empty():
		for key in ["coins","xp","run_id","stars","score"]:
			if not Run.integer(v.last_receipt.get(key),0,1e12):return false
		if v.last_receipt.run_id>v.last_paid_run:return false
	return true

static func read_json(filename:String) -> Variant:
	var parser:=JSON.new()
	return parser.data if parser.parse(FileAccess.get_file_as_string(filename))==OK else null

func load_profile() -> void:
	var selected:Dictionary={};var source:=""
	for candidate in [path,path+".tmp",path+".recovery.tmp",path+".bak"]:
		if not FileAccess.file_exists(candidate):continue
		var v:Variant=read_json(candidate)
		if not valid(v):continue
		if selected.is_empty() or int(v.sequence)>int(selected.sequence):selected=v;source=candidate
	if selected.is_empty():
		if FileAccess.file_exists(path):recovery="Your original save was preserved. Storage recovery is needed."
		return
	data=selected
	if source!=path:
		recovery_source=source;recovery="Recovered your last safe progress."
		if not commit(data):recovery="Progress recovered. Please free storage before continuing."

func commit(next:Dictionary) -> bool:
	if not valid(next):last_error="Progress could not be validated. Please retry.";return false
	var staged:=path+(".recovery.tmp" if recovery_source==path+".tmp" else ".tmp")
	next=next.duplicate(true);next.sequence=int(data.sequence)+1
	var file:=FileAccess.open(staged,FileAccess.WRITE)
	if file==null:last_error="Storage is unavailable. Progress is paused.";return false
	file.store_string(JSON.stringify(next));file.flush();var error:=file.get_error();file.close()
	if error!=OK:_discard(staged);last_error="Progress could not be written.";return false
	if FileAccess.file_exists(path):
		if valid(read_json(path)):
			if DirAccess.copy_absolute(path,path+".bak")!=OK:_discard(staged);last_error="The save backup could not be written.";return false
		elif not FileAccess.file_exists(path+".corrupt"):
			if DirAccess.copy_absolute(path,path+".corrupt")!=OK:_discard(staged);last_error="Your original save could not be preserved.";return false
	if DirAccess.rename_absolute(staged,path)!=OK:_discard(staged);last_error="Progress could not be replaced.";return false
	data=next;last_error="";recovery_source="";return true

func _discard(staged:String) -> void:
	if staged!=recovery_source and FileAccess.file_exists(staged):DirAccess.remove_absolute(staged)

func level() -> int:return 1+int(sqrt(float(data.xp)/80.0))

func frontier() -> int:
	for i in range(36):
		if i>=data.stars.size() or int(data.stars[i])==0:return i
	return 35

func new_run() -> int:
	if not data.active.is_empty():last_error="Resume or end your current incident first.";return 0
	var n:=data.duplicate(true);var id:=int(n.next_run);n.next_run=id+1
	return id if commit(n) else 0

func store_run(snapshot:Dictionary) -> bool:
	var n:=data.duplicate(true);n.active=snapshot.duplicate(true);return commit(n)

func abandon() -> bool:
	var n:=data.duplicate(true);n.active={};return commit(n)

func settle(run:RefCounted,current_day:int) -> Dictionary:
	if not run.done or run.run_id<=int(data.last_paid_run) or run.run_id!=int(data.next_run)-1:return {}
	var n:=data.duplicate(true)
	var engaged:bool=run.sprayed_seconds>=0.1
	var daily_bonus:bool=run.mode=="daily" and run.won and run.day==current_day and current_day>int(n.daily_paid)
	var pay:=0;var earned_xp:=0
	if engaged:
		pay=(45+run.doused*6+run.stars()*8) if run.won else run.doused*2
		earned_xp=(55+run.doused*9) if run.won else run.doused*4
		if run.mode=="endless":pay+=run.waves_cleared*20;earned_xp+=run.waves_cleared*25
	if daily_bonus:
		pay+=70;earned_xp+=100;n.daily_paid=current_day;n.totals.daily_clears+=1
	n.coins+=pay;n.xp+=earned_xp;n.last_paid_run=run.run_id;n.active={}
	n.totals.rounds+=int(engaged);n.totals.clears+=int(run.won and engaged);n.totals.perfect+=int(run.mode=="campaign" and run.stars()==3 and engaged)
	n.totals.doused+=run.doused;n.totals.prevented+=run.prevented
	if run.mode!="endless":n.records.best_score=maxi(n.records.best_score,run.score)
	n.records.endless_wave=maxi(n.records.endless_wave,run.waves_cleared)
	if run.won:n.records.best_integrity=maxi(n.records.best_integrity,int(run.integrity()))
	if run.mode=="campaign" and run.won:
		while n.stars.size()<=run.incident:n.stars.append(0)
		n.stars[run.incident]=maxi(n.stars[run.incident],run.stars())
	_roll_day(n,current_day)
	if n.quest_day==current_day:
		n.quest.doused+=run.doused;n.quest.clears+=int(run.won and engaged);n.quest.prevented+=run.prevented
	var receipt:Dictionary={"coins":pay,"xp":earned_xp,"run_id":run.run_id,"stars":run.stars(),"score":run.score}
	n.last_receipt=receipt
	return receipt if commit(n) else {}

static func _roll_day(n:Dictionary,day:int) -> void:
	if day>int(n.quest_day):n.quest_day=day;n.quest={"doused":0,"clears":0,"prevented":0};n.quest_claims=[]

func login(day:int) -> int:
	if day<=int(data.login_day):return 0
	var n:=data.duplicate(true)
	n.streak=int(n.streak)%7+1 if day==int(n.login_day)+1 else 1
	n.login_day=day;n.records.best_streak=maxi(n.records.best_streak,n.streak)
	var reward:=login_reward(n.streak);n.coins+=reward;_roll_day(n,day)
	return reward if commit(n) else 0

func claim_quest(key:String,day:int) -> bool:
	if key not in QUESTS or data.quest_day!=day or key in data.quest_claims or int(data.quest[key])<int(QUESTS[key].target):return false
	var n:=data.duplicate(true);n.coins+=35;n.xp+=50;n.quest_claims.append(key);return commit(n)

func purchase(key:String) -> bool:
	if key not in Upgrades.KEYS:return false
	var rank:=int(data.gear[key]);var price:=Upgrades.price(key,rank)
	if rank>=4 or data.coins<price:return false
	var n:=data.duplicate(true);n.coins-=price;n.gear[key]=rank+1;return commit(n)

func setting(key:String,value:bool) -> bool:
	if key not in ["music","sfx","motion","vibration"]:return false
	var n:=data.duplicate(true);n[key]=value;return commit(n)

func metrics() -> Dictionary:
	var result:Dictionary=data.totals.duplicate(true)
	result.merge(data.records,true);result.xp=int(data.xp);result.level=level();result.stars=0;result.campaign_clears=0;result.upgrades=0
	for key in Upgrades.KEYS:result.upgrades+=int(data.gear[key])
	for i in range(6):result["district_%d"%i]=0
	for i in range(data.stars.size()):
		result.stars+=int(data.stars[i]);result.campaign_clears+=int(data.stars[i]>0);result["district_%d"%int(i/6)]+=int(data.stars[i]>0)
	return result

func update_achievements(catalog:Dictionary) -> Array:
	var stats:=metrics();var newly:Array=[];var n:=data.duplicate(true)
	for item in catalog.get("achievements",[]):
		if not n.achievements.get(item.id,false) and int(stats.get(item.metric,0))>=int(item.threshold):n.achievements[item.id]=true;newly.append(item.id)
	if not newly.is_empty() and not commit(n):return []
	return newly
