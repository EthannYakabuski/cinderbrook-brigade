extends RefCounted
const KEYS := ["pump","tank","nozzle","refill","foam"]
const NAMES := {"pump":"Copper pump","tank":"Reserve tank","nozzle":"Sweep nozzle","refill":"Hydrant flow","foam":"Gentle foam"}
const DETAILS := {"pump":"Stronger cooling: +8% per rank.","tank":"More water: +15 units per rank.","nozzle":"Wider spray: +0.10 m per rank.","refill":"Faster refill: +12% per rank.","foam":"Longer wet protection: +15% per rank."}
static func normalize(value:Dictionary) -> Dictionary:
	var result:Dictionary={}
	for key in KEYS:result[key]=clampi(int(value.get(key,0)),0,4)
	return result
static func price(key:String, rank:int) -> int:
	return 55+rank*60+rank*rank*20+KEYS.find(key)*5
static func effect(key:String,rank:int) -> String:
	match key:
		"pump":return "%d%% cooling"%(100+8*rank)
		"tank":return "%d water"%(100+15*rank)
		"nozzle":return "%.1f m radius"%(1.05+0.10*rank)
		"refill":return "%d%% refill"%(100+12*rank)
		"foam":return "%d%% wet protection"%(100+15*rank)
	return ""
