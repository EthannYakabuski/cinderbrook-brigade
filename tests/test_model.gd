extends SceneTree
const Run=preload("res://game/run.gd")
const Incidents=preload("res://game/incidents.gd")
const Upgrades=preload("res://game/upgrades.gd")
var checks:=0
var failures:Array=[]

func check(value:bool,message:String) -> void:
	checks+=1
	if not value:failures.append(message);printerr("FAIL: "+message)

static func solve(run:RefCounted) -> void:
	var filling:=false
	for tick in range(12000):
		if run.done:return
		if run.water<8:filling=true
		if run.water>run.capacity*0.8:filling=false
		var target:=Vector2.ZERO;var hottest:=-1.0
		for cell in run.cells:
			if float(cell.heat)>hottest and float(cell.heat)>0.01:hottest=float(cell.heat);target=Vector2(cell.x,cell.z)
		var held:=not filling and hottest>=0
		if hottest<0:
			var ember:Dictionary=run.next_ember()
			if not ember.is_empty():
				var cell:Dictionary=run.cells[ember.cell];target=Vector2(cell.x,cell.z);held=not filling and float(cell.wet)<65 and float(ember["in"])<4
		run.advance(1.0/30.0,target,held)

func _init() -> void:
	var titles:Dictionary={};var shapes:Dictionary={};var worst_time:=0.0;var worst_integrity:=100.0
	for i in range(36):
		var spec:Dictionary=Incidents.make(i);check(not titles.has(spec.name),"unique title %d"%i);titles[spec.name]=true
		var shape:String=JSON.stringify(spec.layout);check(not shapes.has(shape),"authored layout unique %d"%i);shapes[shape]=true
		check(spec.layout.size()>=4 and spec.layout.size()<=9,"content bounds %d"%i)
		var r:=Run.new();r.start(i+1,"campaign",i,{},20771);check(Run.valid_snapshot(r.snapshot()),"fresh snapshot %d"%i);solve(r)
		check(r.done and r.won,"base gear campaign %d"%i);check(r.stars()==3,"base gear3stars %d"%i);check(Run.valid_snapshot(r.snapshot()),"completed snapshot %d"%i)
		worst_time=maxf(worst_time,r.elapsed);worst_integrity=minf(worst_integrity,r.integrity())
	for day in range(20760,20832):
		var r:=Run.new();r.start(day,"daily",0,{},day);solve(r);check(r.done and r.won,"base gear daily %d"%day);check(r.stars()==3,"daily3stars %d"%day)
	var endless:=Run.new();endless.start(100,"endless",0,{},20771)
	for wave in range(1,9):
		solve(endless);check(endless.won and endless.waves_cleared==wave,"endless wave %d"%wave);check(Run.valid_snapshot(endless.snapshot()),"endless saved %d"%wave)
		if wave<8:check(endless.next_wave(),"next wave %d"%wave)
	var held:=Run.new();held.start(200,"campaign",35,{},20771);held.water=0
	for i in range(120):held.advance(1.0/60,Vector2(4,5),true)
	check(held.water==0,"empty held tank does not auto-refill");held.advance(0.2,Vector2.ZERO,false);check(held.water>8,"release refills promptly")
	var idle:=Run.new();idle.start(201,"campaign",0,{},20771)
	for i in range(12000):
		if idle.done:break
		idle.advance(1.0/60,Vector2.ZERO,false)
	check(idle.done and not idle.won,"no-input failure");check(idle.sprayed_seconds==0 and idle.doused==0,"no imaginary idle activity")
	check(not idle.apply_recovery(),"no recovery without earned");check(idle.mark_recovery_earned(),"earned entitlement accepted");check(not idle.mark_recovery_earned(),"duplicate earned ignored")
	var restored:RefCounted=Run.restore(idle.snapshot());check(restored.recovery_earned and restored.done,"pending earned survives restart");check(restored.apply_recovery(),"earned recovery applied");check(not restored.apply_recovery(),"recovery one-time");check(not restored.done and restored.water==restored.capacity*0.8,"limited emergency water");check(restored.limit<=idle.limit+30.1,"limited emergency time")
	var snap:Dictionary=held.snapshot();var bad:Dictionary=snap.duplicate(true);bad.spec={};check(not Run.valid_snapshot(bad),"reject spec injection");bad=snap.duplicate(true);bad.cooling="bad";check(not Run.valid_snapshot(bad),"reject cooling injection");bad=snap.duplicate(true);bad.cells[0].heat=NAN;check(not Run.valid_snapshot(bad),"reject nan");bad=snap.duplicate(true);bad.cells[0].x=99;check(not Run.valid_snapshot(bad),"reject moved authored cell");bad=snap.duplicate(true);bad.gear.tank=99;check(not Run.valid_snapshot(bad),"reject impossible gear")
	var first:=Run.new();first.start(300,"campaign",18,{},20771);first.advance(1.0/30,Vector2(-2.5,-3.2),true);var copy:RefCounted=Run.restore(first.snapshot())
	for i in range(180):first.advance(1.0/30,Vector2(0,-2.2),true);copy.advance(1.0/30,Vector2(0,-2.2),true)
	check(JSON.stringify(first.snapshot())==JSON.stringify(copy.snapshot()),"resume deterministic exact continuation")
	var boosted:=Run.new();boosted.start(301,"campaign",35,{"pump":4,"tank":4,"nozzle":4,"refill":4,"foam":4},20771);solve(boosted);check(boosted.won,"maximum equipment playable");check(boosted.capacity==160 and is_equal_approx(boosted.radius,1.45),"upgrade effects exact")
	print("MODEL METRICS campaign=36 daily=72 endless=8 worst_baseline_seconds=%.2f worst_integrity=%.2f"%[worst_time,worst_integrity])
	if failures.is_empty():print("MODEL PASS checks=%d"%checks);quit(0)
	else:printerr("MODEL FAILED %d / %d"%[failures.size(),checks]);quit(1)
