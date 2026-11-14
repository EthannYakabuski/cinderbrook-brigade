extends RefCounted
const COUNT := 36
const THEMES := ["Maple Mews","Pine Camp","Warehouse Row","Orchard Bend","Lakeside Fair","Lantern Heights"]
# Each row is individually composed: title, tactical brief, seconds, growth, wind,
# explicit [x,z,initial heat,object kind] locations, and [time,cell,power] embers.
const DATA := [
	["A Little Warm Welcome","Hold over the glowing shed. Lift your finger to refill.",45,1.4,0.0,[[-1.4,0,58,"shed"],[1.5,-1.8,0,"cottage"],[-1.7,-3,0,"tree"],[1.6,2.1,0,"tree"]],[]],
	["Garden Gate","Sweep between the two fires. Watch the blue water bar.",50,1.7,0.1,[[-2,-1.7,62,"shed"],[1.7,1.4,64,"cottage"],[1.6,-2.3,0,"tree"],[-1.4,2.6,0,"tree"]],[]],
	["The Shared Hedge","Close neighbors share heat. Wet both with a wide sweep.",55,2.0,0.15,[[-1.9,-1.5,70,"cottage"],[-0.3,-1.5,25,"tree"],[1.4,-1.5,58,"shed"],[-1.4,2.0,0,"tree"],[1.5,2.3,0,"cottage"]],[]],
	["Ember on the Breeze","A gold ring warns where an ember will land. Wet it early.",58,2.0,0.35,[[-2.2,-2.3,64,"cottage"],[1.7,-2.3,48,"shed"],[0,0.2,0,"tree"],[-2,2.6,0,"shed"],[2,2.5,0,"tree"]],[[7,3,55]]],
	["Backyard Barbecue","Cool the center first, then follow the glowing edges.",60,2.4,0.25,[[-2.5,-2.5,50,"cottage"],[0,-2.1,60,"shed"],[2.5,-2.5,0,"tree"],[-1.3,0.4,72,"crates"],[1.4,0.4,0,"tree"],[0,2.8,45,"cottage"]],[[9,4,46]]],
	["Mews Evening","A final garden sweep. Keep an eye on the far corner.",65,2.6,0.4,[[-2.6,-3,70,"cottage"],[0,-2.8,0,"tree"],[2.6,-2.5,65,"shed"],[-2,0.1,48,"tree"],[1,0,55,"cottage"],[-1.5,2.8,0,"shed"],[2,2.7,44,"tree"]],[[11,1,52]]],
	["Pine Needle Path","Tents need a gentle sweep. Trees can carry the glow.",60,2.4,0.35,[[-2.3,-2.2,62,"tent"],[0,-2.8,0,"tree"],[2.2,-1.9,68,"tent"],[-1.2,0.8,50,"tree"],[1.5,2.5,0,"tent"]],[]],
	["Three Little Tents","A triangle of tents rewards careful sweeping.",62,2.5,0.2,[[0,-3,74,"tent"],[-2.5,0,66,"tent"],[2.5,0,60,"tent"],[-1.2,2.8,0,"tree"],[1.2,2.8,48,"crates"]],[[8,3,40]]],
	["The Picnic Line","Cool the hot end of the picnic line before it spreads.",64,2.7,0.45,[[-2.7,-2.6,78,"tree"],[-1,-1.3,50,"tent"],[0.7,0,18,"crates"],[2.4,1.3,0,"tent"],[-2,2.8,55,"tree"],[2,-2.8,0,"tree"]],[]],
	["Canvas and Cedar","Wet the gap between canvas and cedar.",68,2.9,0.5,[[-2.4,-2.9,70,"tent"],[0,-2.8,0,"tree"],[2.4,-2.6,58,"tree"],[-1.6,-0.1,64,"crates"],[1.4,0.6,24,"tent"],[-2.2,2.8,0,"tree"],[2.2,2.8,52,"tent"]],[[12,5,56]]],
	["Riverside Sparks","Two ember warnings arrive in order. Follow their gold rings.",70,3.0,0.6,[[-2.6,-3,70,"tree"],[0.3,-3,60,"tent"],[2.7,-0.8,0,"tree"],[-2.7,-0.1,48,"tent"],[0,1.2,55,"crates"],[-1.8,3,0,"tree"],[2.3,2.8,0,"tent"]],[[8,2,52],[15,6,58]]],
	["Camp Quiet","Bring every corner of the camp back to a quiet blue.",72,3.1,0.55,[[-2.7,-3,74,"tent"],[0,-3,54,"tree"],[2.7,-3,0,"tent"],[-2.1,-0.2,65,"tree"],[1.8,-0.2,57,"tent"],[-2.6,2.8,0,"tent"],[0,2.5,40,"crates"],[2.6,2.8,0,"tree"]],[[13,2,62]]],
	["Loading Bay","Crates are close together. Sweep the whole cluster.",64,2.7,0.3,[[-2.3,-2.4,75,"crates"],[-0.6,-2.4,50,"crates"],[1.8,-2.1,0,"shed"],[-2,0.8,60,"shed"],[1.8,1.3,55,"crates"],[0,3,0,"tree"]],[]],
	["Red Brick Lane","The lane splits the scene. Finish one side, then cross.",68,2.9,0.45,[[-2.5,-3,75,"shed"],[-2.5,0,55,"crates"],[-2.5,2.8,0,"crates"],[2.5,-2.8,70,"shed"],[2.5,0.2,45,"crates"],[2.5,2.9,0,"tree"]],[[10,2,48]]],
	["Pallet Puzzle","A small center spray reaches several stacked pallets.",68,3.1,0.4,[[-1,-2,78,"crates"],[0.8,-2.1,58,"crates"],[-1,0,65,"crates"],[0.8,0,30,"crates"],[-2.8,2.6,0,"shed"],[2.7,2.7,55,"shed"]],[[12,4,55]]],
	["The Crosswind","The breeze favors the eastern crates. Keep them damp.",72,3.3,0.85,[[-2.6,-2.8,80,"shed"],[0,-2.6,30,"crates"],[2.6,-2.4,0,"crates"],[-2.6,0.5,70,"crates"],[0,0.4,38,"shed"],[2.6,0.2,0,"crates"],[0,3,54,"tree"]],[[14,2,65]]],
	["Late Delivery","The back loading bays need attention before the front.",74,3.2,0.5,[[-2.6,-3.3,83,"shed"],[0,-3.1,72,"crates"],[2.6,-3,65,"shed"],[-2.2,-0.1,0,"crates"],[1.9,0.2,45,"crates"],[-1.4,2.8,58,"shed"],[1.5,2.8,0,"tree"]],[[11,3,50],[18,6,52]]],
	["Closing Time","Clear both warehouse courts, then catch the last spark.",76,3.4,0.7,[[-2.5,-3,75,"shed"],[0,-2.5,65,"crates"],[2.5,-3,0,"shed"],[-2.5,0,55,"crates"],[0,0.2,42,"crates"],[2.5,0,70,"crates"],[-2,2.8,0,"tree"],[2,2.8,52,"shed"]],[[15,2,66]]],
	["Apple Morning","Cool the tree crowns before their neighbors warm.",68,3.0,0.3,[[-2.5,-2.7,72,"tree"],[0,-2.7,54,"tree"],[2.5,-2.7,0,"tree"],[-1.3,0.2,63,"tree"],[1.3,0.2,0,"tree"],[0,3,52,"shed"]],[]],
	["Basket Run","The crates beneath the trees need water too.",72,3.2,0.45,[[-2.4,-3,77,"tree"],[2.4,-3,67,"tree"],[-2.4,-0.2,32,"crates"],[0,0,64,"tree"],[2.4,-0.2,0,"crates"],[-1.4,2.8,56,"tree"],[1.4,2.8,0,"shed"]],[[10,4,58]]],
	["Orchard Zigzag","Follow the zigzag, keeping the middle damp.",73,3.3,0.55,[[-2.5,-3.2,80,"tree"],[0,-2.2,60,"tree"],[2.5,-1.2,40,"tree"],[0,0.2,30,"tree"],[-2.5,1.6,65,"tree"],[0,2.6,0,"crates"],[2.5,3.2,0,"tree"]],[[13,6,60]]],
	["The Old Tool Shed","The shed is hot; a wet orchard gives you room to work.",76,3.4,0.7,[[0,-3.2,87,"shed"],[-2.5,-2,62,"tree"],[2.5,-2,62,"tree"],[-2.5,0.8,0,"tree"],[2.5,0.8,48,"tree"],[0,0,52,"crates"],[-1.4,3,0,"tree"],[1.4,3,0,"tree"]],[[12,3,60],[18,7,55]]],
	["Petal Wind","Two diagonal fronts. Save some water for the second.",78,3.5,0.85,[[-2.7,-3.2,82,"tree"],[-0.7,-1.8,65,"tree"],[1.2,-0.4,35,"tree"],[2.7,1.3,0,"tree"],[2.5,-3,68,"tree"],[-2.6,0.8,60,"shed"],[-1.2,3,0,"crates"],[1.4,3,0,"tree"]],[[16,3,68]]],
	["Harvest Saved","A complete orchard sweep makes a bright harvest.",80,3.6,0.7,[[-2.6,-3.2,78,"tree"],[0,-3.2,66,"tree"],[2.6,-3.2,0,"tree"],[-2.6,0,60,"tree"],[0,0,48,"shed"],[2.6,0,72,"tree"],[-2.6,3,0,"tree"],[0,3,56,"crates"],[2.6,3,0,"tree"]],[[11,2,62],[19,8,66]]],
	["Opening the Fair","Keep the booths bright and the bunting safe.",72,3.2,0.4,[[-2.4,-2.8,75,"stall"],[0,-2.6,55,"stall"],[2.4,-2.8,0,"stall"],[-1.8,0.5,68,"tree"],[1.8,0.5,48,"crates"],[0,3,0,"tent"]],[]],
	["The Cake Walk","A horseshoe of booths shares heat along the curve.",76,3.4,0.5,[[-2.6,1.9,80,"stall"],[-2.5,-0.8,65,"stall"],[-1.3,-3,45,"stall"],[1.3,-3,0,"stall"],[2.5,-0.8,70,"stall"],[2.6,1.9,0,"stall"],[0,2.7,50,"tree"]],[[12,3,60]]],
	["Ribbon Crossing","The middle lane lets you switch fronts quickly.",78,3.5,0.65,[[-2.6,-3.2,78,"tent"],[0,-3.2,64,"stall"],[2.6,-3.2,0,"tree"],[-2.6,0,58,"stall"],[2.6,0,73,"stall"],[-2.6,3,0,"tree"],[0,3,55,"crates"],[2.6,3,0,"tent"]],[[10,2,62],[18,5,58]]],
	["Lakeside Lanterns","Gold ember rings travel down the lakeside stalls.",80,3.6,0.8,[[-2.5,-3,82,"stall"],[0,-2.7,67,"tree"],[2.5,-3,0,"stall"],[-2.5,0,60,"stall"],[0,0,45,"crates"],[2.5,0,0,"stall"],[-1.5,3,72,"tent"],[1.5,3,0,"tree"]],[[9,2,58],[15,5,64],[21,7,54]]],
	["The Grand Picnic","Small water sweeps can cool two tables at a time.",82,3.7,0.6,[[-2.5,-3.1,80,"stall"],[-0.8,-2.4,60,"crates"],[1,-3.1,0,"stall"],[2.6,-1.1,70,"tree"],[-2.6,0.3,57,"tent"],[-0.8,1.2,45,"crates"],[1,1.8,0,"stall"],[2.7,3.1,62,"tent"]],[[13,2,63],[20,6,58]]],
	["After the Applause","One last round of the fair. No booth left behind.",84,3.8,0.9,[[-2.6,-3.2,85,"stall"],[0,-3.2,65,"tree"],[2.6,-3.2,75,"stall"],[-2.6,0,45,"tent"],[0,0,55,"crates"],[2.6,0,0,"tent"],[-2.6,3,68,"stall"],[0,3,0,"tree"],[2.6,3,0,"stall"]],[[12,5,66],[22,8,70]]],
	["Up on the Hill","Roof sparks travel downhill. Read the gold warning rings.",78,3.5,0.6,[[-2.5,-3.2,85,"cottage"],[0,-2.7,65,"tree"],[2.5,-3.2,72,"cottage"],[-2,0.3,50,"shed"],[2,0.3,0,"tree"],[0,3,58,"cottage"]],[[13,4,62]]],
	["Steps and Gardens","A staggered path invites a steady downward sweep.",80,3.7,0.7,[[-2.6,-3.3,82,"cottage"],[0,-2.6,68,"tree"],[2.5,-1.6,0,"shed"],[-2.4,-0.3,74,"tree"],[0,0.7,52,"cottage"],[2.5,2,0,"tree"],[-1.4,3.2,60,"shed"]],[[10,2,60],[18,5,65]]],
	["Lantern Lane","Two tidy rows, one busy hose. Refill between sweeps.",83,3.8,0.8,[[-2.2,-3.3,86,"cottage"],[2.2,-3.3,78,"cottage"],[-2.2,-1,65,"tree"],[2.2,-1,52,"tree"],[-2.2,1.3,38,"shed"],[2.2,1.3,0,"shed"],[-2.2,3.4,64,"tree"],[2.2,3.4,0,"tree"]],[[14,5,68],[21,7,62]]],
	["Rooftop Relay","Put out each hot roof before chasing the next spark.",86,3.9,0.95,[[-2.6,-3.3,88,"cottage"],[0,-3.1,70,"shed"],[2.6,-3.3,0,"cottage"],[-2.6,0,76,"cottage"],[0,0.2,50,"tree"],[2.6,0,60,"cottage"],[-2,3.1,0,"shed"],[2,3.1,68,"tree"]],[[9,2,68],[17,6,65],[24,4,55]]],
	["The Long Evening","A long shift needs a rhythm: sweep, lift, sweep.",88,4.0,1.0,[[-2.6,-3.3,86,"cottage"],[0,-3.3,72,"tree"],[2.6,-3.3,82,"shed"],[-2.6,0,64,"tree"],[0,0,40,"crates"],[2.6,0,0,"tree"],[-2.6,3.2,72,"shed"],[0,3.2,0,"tree"],[2.6,3.2,56,"cottage"]],[[12,5,72],[21,7,66]]],
	["A Town Full of Light","Bring Cinderbrook home safely. Every corner matters.",92,4.1,0.9,[[-2.6,-3.3,88,"cottage"],[0,-3.3,72,"tree"],[2.6,-3.3,82,"cottage"],[-2.6,0,65,"shed"],[0,0,55,"tree"],[2.6,0,75,"stall"],[-2.6,3.2,0,"tent"],[0,3.2,68,"tree"],[2.6,3.2,0,"cottage"]],[[10,6,68],[18,8,72],[26,1,60]]]
]
static func make(index:int, mode:String="campaign", day:int=0, wave:int=1) -> Dictionary:
	var selected:=clampi(index,0,COUNT-1)
	if mode=="daily":selected=posmod(day*17+11,COUNT)
	if mode=="endless":selected=posmod((wave-1)*7+4,COUNT)
	var row:Array=DATA[selected]
	var result:Dictionary={"index":selected,"name":row[0],"brief":row[1],"theme":int(selected/6),"limit":float(row[2]),"growth":float(row[3]),"wind":float(row[4]),"wind_dir":[1.0,0.3],"spread":1.0,"layout":row[5].duplicate(true),"embers":row[6].duplicate(true),"props":[]}
	if mode=="daily":
		result.growth*=1.0+0.025*posmod(day,5);result.wind_dir=[1.0 if posmod(day,2)==0 else -1.0,0.3]
	if mode=="endless":
		result.growth*=1.0+minf(1.1,(wave-1)*0.06);result.limit=maxf(45,result.limit-(wave-1)*0.6)
	return result
