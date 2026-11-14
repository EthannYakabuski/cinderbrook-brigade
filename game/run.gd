extends RefCounted
const Incidents=preload("res://game/incidents.gd")
const Upgrades=preload("res://game/upgrades.gd")
const STEP := 1.0/60.0
var run_id:=0
var mode:="campaign"
var incident:=0
var day:=0
var wave:=1
var waves_cleared:=0
var gear:Dictionary={}
var spec:Dictionary={}
var cells:Array=[]
var elapsed:=0.0
var total_elapsed:=0.0
var limit:=60.0
var water:=100.0
var capacity:=100.0
var radius:=1.05
var cooling:=36.0
var refill:=42.0
var foam:=1.0
var accumulator:=0.0
var ember_cursor:=0
var doused:=0
var stage_doused:=0
var prevented:=0
var stage_prevented:=0
var water_used:=0.0
var sprayed_seconds:=0.0
var score:=0
var banked_score:=0
var done:=false
var won:=false
var failure:=""
var recovery_earned:=false
var recovery_used:=false
var spraying:=false
var stage_start_doused:=0

func start(id:int, kind:String, index:int, equipment:Dictionary, current_day:int) -> void:
	run_id=id;mode=kind;incident=clampi(index,0,35);day=current_day;gear=Upgrades.normalize(equipment)
	wave=1;waves_cleared=0;elapsed=0;total_elapsed=0;doused=0;prevented=0;water_used=0;sprayed_seconds=0;score=0;banked_score=0;recovery_earned=false;recovery_used=false
	_prepare_stage()

func _prepare_stage() -> void:
	spec=Incidents.make(incident,mode,day,wave)
	capacity=100.0+15.0*gear.tank;radius=1.05+0.1*gear.nozzle;cooling=36.0*(1.0+0.08*gear.pump);refill=42.0*(1.0+0.12*gear.refill);foam=1.0+0.15*gear.foam
	cells=[]
	for item in spec.layout:
		cells.append({"x":float(item[0]),"z":float(item[1]),"heat":float(item[2]),"wet":0.0,"integrity":100.0,"kind":str(item[3]),"peak":float(item[2]),"burned":float(item[2])>0,"cooled":false})
	elapsed=0;limit=spec.limit;water=capacity;ember_cursor=0;accumulator=0;done=false;won=false;failure="";spraying=false;stage_doused=0;stage_start_doused=doused;stage_prevented=0

func next_wave() -> bool:
	if mode!="endless" or not done or not won:return false
	banked_score=score;wave+=1;_prepare_stage();return true

func advance(delta:float, aim:Vector2, held:bool) -> void:
	if done:return
	accumulator+=clampf(delta,0.0,0.25)
	while accumulator+0.0000001>=STEP and not done:
		accumulator-=STEP;_step(STEP,aim,held)
	accumulator=maxf(0,accumulator)

func _step(dt:float, aim:Vector2, held:bool) -> void:
	elapsed+=dt;total_elapsed+=dt
	while ember_cursor<spec.embers.size() and elapsed>=float(spec.embers[ember_cursor][0]):
		var ember:Array=spec.embers[ember_cursor]
		var cell:Dictionary=cells[int(ember[1])]
		if float(cell.wet)>=24:prevented+=1;stage_prevented+=1;cell.wet=maxf(0,cell.wet-15)
		else:cell.heat=maxf(cell.heat,float(ember[2]));cell.burned=true;cell.cooled=false
		ember_cursor+=1
	spraying=held and water>0.05
	if spraying:
		var spent:=minf(water,13.0*dt);water-=spent;water_used+=spent;sprayed_seconds+=dt
	elif not held:water=minf(capacity,water+refill*dt)
	var spread:Array=[];spread.resize(cells.size());spread.fill(0.0)
	for i in range(cells.size()):
		var source:Dictionary=cells[i]
		if float(source.heat)<55:continue
		for j in range(cells.size()):
			if i==j:continue
			var other:Dictionary=cells[j]
			var distance:=Vector2(source.x-other.x,source.z-other.z).length()
			var downwind:float=clampf((float(other.x)-float(source.x))*float(spec.wind_dir[0]),-1,1)
			var reach:float=2.25+0.4*float(spec.wind)*maxf(0,downwind)
			if distance<reach and float(other.wet)<18:
				spread[j]+=dt*float(spec.growth)*0.55*(1.0-distance/(reach+0.5))*(1.0+maxf(0,downwind)*float(spec.wind))
	for i in range(cells.size()):
		var cell:Dictionary=cells[i]
		var was_hot:bool=float(cell.heat)>0.01
		var distance:=aim.distance_to(Vector2(cell.x,cell.z))
		var hit:=spraying and distance<=radius
		if hit:
			var strength:=1.0-0.20*distance/radius
			cell.heat=maxf(0,float(cell.heat)-cooling*strength*dt)
			cell.wet=minf(100,float(cell.wet)+42.0*foam*dt)
		else:cell.wet=maxf(0,float(cell.wet)-2.1*dt/foam)
		if float(cell.heat)>0.01:
			cell.heat=clampf(float(cell.heat)+float(spec.growth)*dt*(1.0-float(cell.wet)/65.0),0,100)
		elif float(spread[i])>0 and float(cell.wet)<18:cell.heat=0.15
		cell.heat=minf(100,float(cell.heat)+float(spread[i]))
		if float(cell.heat)<0.4 and hit:cell.heat=0.0
		if float(cell.heat)>0.01:
			cell.integrity=maxf(0,float(cell.integrity)-dt*float(cell.heat)/100.0*1.15)
			cell.burned=true;cell.peak=maxf(cell.peak,cell.heat)
		if was_hot and float(cell.heat)<=0.01:
			doused+=1;stage_doused+=1;cell.cooled=true
	if integrity()<=0.1:_finish(false,"The neighborhood needs a fresh start.")
	elif elapsed>=limit:_finish(false,"Time ran out. Your crew is safe.")
	elif burning()==0 and ember_cursor>=spec.embers.size():_finish(true,"")

func _finish(success:bool, reason:String) -> void:
	done=true;won=success;spraying=false;failure=reason
	if success:
		if mode=="endless":waves_cleared=maxi(waves_cleared,wave)
		score=banked_score+int(integrity()*18.0)+stage_doused*120+int(maxf(0,limit-elapsed)*8.0)+stage_prevented*75
	else:score=banked_score+stage_doused*80

func burning() -> int:
	var result:=0
	for cell in cells:result+=int(float(cell.heat)>0.01)
	return result

func integrity() -> float:
	var result:=0.0
	for cell in cells:result+=float(cell.integrity)
	return result/maxi(1,cells.size())

func stars() -> int:
	if not won:return 0
	if integrity()>=80 and elapsed<=limit*0.8:return 3
	if integrity()>=55:return 2
	return 1

func next_ember() -> Dictionary:
	if ember_cursor>=spec.embers.size():return {}
	var e:Array=spec.embers[ember_cursor]
	return {"in":maxf(0,float(e[0])-elapsed),"cell":int(e[1]),"heat":float(e[2])}

func mark_recovery_earned() -> bool:
	if not done or won or recovery_used or recovery_earned:return false
	recovery_earned=true;return true

func apply_recovery() -> bool:
	if not done or won or recovery_used or not recovery_earned:return false
	recovery_used=true;recovery_earned=false;done=false;won=false;failure="";water=capacity*0.8;limit=maxf(limit,elapsed)+30.0
	for cell in cells:cell.integrity=minf(100,float(cell.integrity)+35.0)
	return true

func snapshot() -> Dictionary:
	return {"version":1,"run_id":run_id,"mode":mode,"incident":incident,"day":day,"wave":wave,"waves_cleared":waves_cleared,"gear":gear.duplicate(true),"cells":cells.duplicate(true),"elapsed":elapsed,"total_elapsed":total_elapsed,"limit":limit,"water":water,"accumulator":accumulator,"ember_cursor":ember_cursor,"doused":doused,"stage_doused":stage_doused,"stage_start_doused":stage_start_doused,"prevented":prevented,"stage_prevented":stage_prevented,"water_used":water_used,"sprayed_seconds":sprayed_seconds,"score":score,"banked_score":banked_score,"done":done,"won":won,"failure":failure,"recovery_earned":recovery_earned,"recovery_used":recovery_used}

static func number(v:Variant, low:float, high:float) -> bool:
	return (v is int or v is float) and is_finite(float(v)) and float(v)>=low and float(v)<=high

static func integer(v:Variant, low:float, high:float) -> bool:
	return number(v,low,high) and float(v)==floor(float(v))

static func valid_snapshot(v:Variant) -> bool:
	if not v is Dictionary:return false
	var allowed:Dictionary={"version":true,"run_id":true,"mode":true,"incident":true,"day":true,"wave":true,"waves_cleared":true,"gear":true,"cells":true,"elapsed":true,"total_elapsed":true,"limit":true,"water":true,"accumulator":true,"ember_cursor":true,"doused":true,"stage_doused":true,"stage_start_doused":true,"prevented":true,"stage_prevented":true,"water_used":true,"sprayed_seconds":true,"score":true,"banked_score":true,"done":true,"won":true,"failure":true,"recovery_earned":true,"recovery_used":true}
	for key in v:
		if not allowed.has(key):return false
	var integer_limits:Dictionary={"version":[1,1],"run_id":[1,1e12],"incident":[0,35],"day":[0,1e9],"wave":[1,10000],"waves_cleared":[0,10000],"ember_cursor":[0,3],"doused":[0,1e8],"stage_doused":[0,1e8],"stage_start_doused":[0,1e8],"prevented":[0,1e8],"stage_prevented":[0,1e8],"score":[0,1e12],"banked_score":[0,1e12]}
	for key in integer_limits:
		if not integer(v.get(key),integer_limits[key][0],integer_limits[key][1]):return false
	if v.get("mode") not in ["campaign","daily","endless"]:return false
	for key in ["done","won","recovery_earned","recovery_used"]:
		if not v.get(key) is bool:return false
	if not v.get("failure") is String or v.failure.length()>100:return false
	if v.won and not v.done:return false
	if v.recovery_earned and (not v.done or v.won or v.recovery_used):return false
	if not v.get("gear") is Dictionary or v.gear.size()!=5:return false
	for key in Upgrades.KEYS:
		if not integer(v.gear.get(key),0,4):return false
	var spec:Dictionary=Incidents.make(int(v.incident),v.mode,int(v.day),int(v.wave))
	for key in ["elapsed","total_elapsed","water_used","sprayed_seconds"]:
		if not number(v.get(key),0,1e9):return false
	if not number(v.get("limit"),spec.limit,spec.limit+30.1) or not number(v.get("water"),0,100+15*int(v.gear.tank)) or not number(v.get("accumulator"),0,0.26):return false
	if v.elapsed>v.limit+0.1 or v.total_elapsed+0.1<v.elapsed or v.sprayed_seconds>v.total_elapsed+0.1:return false
	if int(v.ember_cursor)>spec.embers.size():return false
	if not v.get("cells") is Array or v.cells.size()!=spec.layout.size():return false
	for i in range(v.cells.size()):
		var cell:Variant=v.cells[i]
		if not cell is Dictionary:return false
		for key in ["heat","wet","integrity","peak"]:
			if not number(cell.get(key),0,100):return false
		if not number(cell.get("x"),-4,4) or not number(cell.get("z"),-5,5):return false
		if absf(float(cell.x)-float(spec.layout[i][0]))>0.001 or absf(float(cell.z)-float(spec.layout[i][1]))>0.001:return false
		if cell.get("kind")!=spec.layout[i][3] or not cell.get("burned") is bool or not cell.get("cooled") is bool:return false
	return true

static func restore(v:Dictionary) -> RefCounted:
	if not valid_snapshot(v):return null
	var result=load("res://game/run.gd").new()
	result.start(int(v.run_id),v.mode,int(v.incident),v.gear,int(v.day))
	result.wave=int(v.wave);result._prepare_stage()
	for key in v:
		if key!="version":result.set(key,v[key].duplicate(true) if v[key] is Dictionary or v[key] is Array else v[key])
	return result
