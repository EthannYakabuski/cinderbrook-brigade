extends Node3D
## Presentation only. The run owns heat, water, wetness, integrity and outcomes.
## All imported models are fitted from their measured nested mesh bounds.

const ROOT := "res://assets/kenney/"
const MODEL_DIR := {
	"car": "car/Models/GLB format/",
	"suburban": "suburban/Models/GLB format/",
	"industrial": "industrial/Models/GLB format/",
	"nature": "nature/Models/GLTF format/",
	"survival": "survival/Models/GLB format/",
	"market": "market/Models/GLB format/",
	"roads": "roads/Models/GLB format/"
}
const PALETTES := [
	[Color("60977b"), Color("213b49"), Color("c8ae87"), Color("3b695c")],
	[Color("527d66"), Color("233b46"), Color("b29b76"), Color("325547")],
	[Color("80958d"), Color("253b4a"), Color("b4ab99"), Color("425f65")],
	[Color("8ba55e"), Color("293f48"), Color("c2ab74"), Color("5d7547")],
	[Color("64a587"), Color("233f4c"), Color("d7c391"), Color("3f766b")],
	[Color("436a6e"), Color("172e42"), Color("928e77"), Color("2d505c")]
]

var camera: Camera3D
var _stage: Node3D
var _cells: Array[Dictionary] = []
var _scenes: Dictionary = {}
var _bounds_cache: Dictionary = {}
var _textures: Dictionary = {}
var _time := 0.0
var _theme := 0
var _hose_origin := Vector3(-2.8, 1.05, 4.65)
var _nozzle: Node3D
var _jet_segments: Array[MeshInstance3D] = []
var _jet_drops: Array[MeshInstance3D] = []
var _splash: Sprite3D
var _aim_ring: MeshInstance3D
var _truck_lights: Array[MeshInstance3D] = []
var _run: RefCounted
var _last_viewport_size := Vector2.ZERO
var _water_mat: StandardMaterial3D
var _foam_mat: StandardMaterial3D
var _wind_marker: Node3D

func build(run: RefCounted, skin: int = 0) -> void:
	_run = run
	_theme = clampi(int(run.spec.get("theme", 0)), 0, 5)
	_time = 0.0
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_cells.clear()
	_jet_segments.clear()
	_jet_drops.clear()
	_truck_lights.clear()
	_stage = Node3D.new()
	_stage.name = "MiniatureNeighborhood"
	add_child(_stage)
	_setup_camera_and_light()
	_build_landscape()
	_build_truck(skin)
	_build_hose()
	for i in range(run.cells.size()):
		_build_cell(run.cells[i], i)
	_build_wind(run.spec)
	_frame_camera()
	call_deferred("_frame_camera")
	update_view(run, Vector2.ZERO, false, 0.0)

func _setup_camera_and_light() -> void:
	camera = Camera3D.new()
	camera.name = "PortraitDioramaCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 15.0
	camera.near = 0.1
	camera.far = 80.0
	camera.position = Vector3(1.8, 16.5, 13.8)
	add_child(camera)
	camera.look_at(Vector3(0.0, 0.0, 0.15))
	camera.make_current()
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = PALETTES[_theme][1].darkened(0.18)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_sky_contribution = 0.0
	env.ambient_light_color = Color("ecf3e9") if _theme != 5 else Color("b9dbe5")
	env.ambient_light_energy = 0.34 if _theme != 5 else 0.46
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 4.0
	env.tonemap_exposure = 0.90
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	environment.environment = env
	add_child(environment)
	var sunlight := DirectionalLight3D.new()
	sunlight.name = "WarmWindowLight"
	sunlight.rotation_degrees = Vector3(-59.0, -27.0, -8.0)
	sunlight.light_color = Color("fff1d7") if _theme != 5 else Color("d7eafb")
	sunlight.light_energy = 0.76 if _theme != 5 else 0.46
	sunlight.shadow_enabled = true
	sunlight.directional_shadow_max_distance = 32.0
	sunlight.shadow_bias = 0.06
	add_child(sunlight)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-32.0, 146.0, 0.0)
	fill.light_color = Color("a8dfeb")
	fill.light_energy = 0.15
	add_child(fill)

func _frame_camera() -> void:
	if not is_instance_valid(camera) or not is_inside_tree():
		return
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x < 1.0 or viewport_size.y < 1.0:
		return
	_last_viewport_size = viewport_size
	camera.position = Vector3(1.8, 16.5, 13.8)
	camera.look_at(Vector3(0.0, 0.0, 0.15))
	camera.size = 15.0
	# Fit the entire authored playable region, with extra front room for the engine.
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for x in [-4.9, 4.9]:
		for z in [-5.8, 6.1]:
			var p := camera.unproject_position(Vector3(x, 0.0, z))
			lo = lo.min(p)
			hi = hi.max(p)
	var fit := maxf((hi.x - lo.x) / (viewport_size.x * 0.96), (hi.y - lo.y) / (viewport_size.y * 0.59))
	camera.size *= fit
	# Shift the camera parallel to its image plane, preserving aim geometry.
	var projected := camera.unproject_position(Vector3(0.0, 0.0, 0.15))
	var y_pixels_per_meter := absf(camera.unproject_position(camera.global_basis.y).y - camera.unproject_position(Vector3.ZERO).y)
	if y_pixels_per_meter > 0.001:
		camera.position += camera.global_basis.y * ((viewport_size.y * 0.482 - projected.y) / y_pixels_per_meter)

func _build_landscape() -> void:
	var palette: Array = PALETTES[_theme]
	_box(_stage, Vector3(0.0, -0.85, 0.0), Vector3(100.0, 0.35, 100.0), palette[1], true)
	_box(_stage, Vector3(0.0, -0.47, 0.1), Vector3(10.2, 0.7, 12.3), palette[3])
	_box(_stage, Vector3(0.0, -0.10, 0.1), Vector3(10.0, 0.20, 12.1), palette[0])
	_box(_stage, Vector3(0.0, 0.014, 4.85), Vector3(9.9, 0.025, 1.55), Color("718b88"))
	_box(_stage, Vector3(0.0, 0.035, 4.01), Vector3(9.9, 0.07, 0.12), Color("dfdfc9"))
	_box(_stage, Vector3(0.0, 0.035, 5.68), Vector3(9.9, 0.07, 0.12), Color("dfdfc9"))
	for i in range(9):
		_box(_stage, Vector3(-4.35 + i * 1.08, 0.035, 4.85), Vector3(0.56, 0.018, 0.065), Color("e8e1c3"))
	# Intersecting narrow footpaths create a readable coherent neighborhood.
	_box(_stage, Vector3(0.0, 0.012, -0.1), Vector3(0.58, 0.022, 8.1), palette[2])
	_box(_stage, Vector3(0.0, 0.014, -0.48), Vector3(8.4, 0.024, 0.42), palette[2])
	for side in [-1.0, 1.0]:
		for i in range(3):
			var pos := Vector3(side * (4.48 + 0.15 * sin(i * 1.9)), 0.0, -4.25 + i * 3.1 + (0.55 if side > 0.0 else 0.0))
			if _theme == 2:
				_model("industrial", "shipping-container-a" if i % 2 == 0 else "shipping-container-b", pos, 0.85, PI * 0.5)
				_model("industrial", "detail-tank", pos + Vector3(-side * 0.12, 0.0, 0.86), 0.40, 0.0)
			elif _theme == 1:
				_model("nature", "tree_pineRoundA" if i % 2 == 0 else "tree_pineRoundB", pos, 1.0, i * 0.73)
				_model("nature", "tree_pineSmallA", pos + Vector3(-side * 0.17, 0.0, 0.80), 0.61, i * 0.51)
			else:
				_model("nature", "tree_default_fall" if _theme == 3 else ("tree_oak" if i % 2 == 0 else "tree_small"), pos, 0.80 + i * 0.09, i * 0.73)
				_model("suburban", "fence-1x2", pos + Vector3(0.0, 0.0, 0.85), 1.05, PI * 0.5)
			_model("nature", "plant_bushSmall", pos + Vector3(-side * 0.23, 0.0, 0.55), 0.42, i)
			_model("nature", "rock_smallC", pos + Vector3(-side * 0.23, 0.0, -0.57), 0.26, i)
	for i in range(7):
		_model("nature", "rock_smallA" if i % 2 == 0 else "rock_smallB", Vector3(-4.5 + i * 1.5, -0.08, 6.0), 0.44, i * 1.14)
	# Theme-specific distant landmarks are decorative and never obscure a target.
	match _theme:
		0:
			_model("suburban", "building-type-e", Vector3(-2.95, 0.0, -5.18), 1.5, 0.0)
			_model("suburban", "building-type-g", Vector3(2.6, 0.0, -5.18), 1.5, 0.0)
			_model("suburban", "fence-1x2", Vector3(-1.1, 0.0, -5.3), 1.3, 0.0)
			_model("suburban", "planter", Vector3(1.05, 0.0, -5.15), 0.7, 0.0)
		1:
			_model("survival", "tent-canvas", Vector3(-2.8, 0.0, -5.2), 1.45, 0.1)
			_model("survival", "campfire-pit", Vector3(-0.7, 0.0, -5.15), 0.72, 0.0)
			_model("survival", "tree-log", Vector3(0.75, 0.0, -5.25), 1.4, PI * 0.45)
			_model("nature", "tree_pineRoundA", Vector3(2.9, 0.0, -5.25), 1.2, 0.0)
		2:
			_model("industrial", "water-tower", Vector3(-3.0, 0.0, -5.15), 1.0, 0.0)
			_model("industrial", "building-j", Vector3(0.2, 0.0, -5.3), 1.65, 0.0)
			_model("industrial", "detail-tank", Vector3(3.0, 0.0, -5.2), 0.86, 0.0)
		3:
			for i in range(5):
				_model("nature", "tree_default_fall", Vector3(-3.6 + i * 1.8, 0.0, -5.3), 1.1, i)
			_model("survival", "resource-planks", Vector3(3.6, 0.0, 3.9), 0.6, 0.0)
		4:
			_box(_stage, Vector3(0.0, 0.006, -5.55), Vector3(9.0, 0.02, 0.76), Color("5cb9bd"))
			for i in range(5):
				_box(_stage, Vector3(-3.7 + i * 1.85, 0.023, -5.5), Vector3(0.8, 0.012, 0.035), Color("c4eeea"))
			_model("survival", "tent-canvas", Vector3(-2.85, 0.0, -4.75), 1.1, 0.0)
			_model("market", "display-fruit", Vector3(2.8, 0.0, -4.8), 1.0, 0.0)
			_bunting(Vector3(-4.5, 2.8, -4.75), Vector3(4.5, 2.8, -4.75))
		5:
			_model("suburban", "building-type-j", Vector3(-2.8, 0.0, -5.3), 1.5, 0.0)
			_model("suburban", "building-type-n", Vector3(2.8, 0.0, -5.3), 1.5, 0.0)
			_bunting(Vector3(-4.45, 2.8, -4.9), Vector3(4.45, 2.8, -4.9))
	for x in [-4.25, 4.25]:
		_lantern(Vector3(x, 0.0, 3.65))
		if _theme == 5:
			_lantern(Vector3(x, 0.0, -3.65))
	_model("car", "cone", Vector3(-4.45, 0.0, 4.6), 0.28, 0.0)
	_model("car", "cone", Vector3(4.45, 0.0, 5.1), 0.28, 0.0)

func _build_truck(skin: int) -> void:
	var truck := _model("car", "firetruck", Vector3(-2.65, 0.04, 4.85), 2.15, PI * 0.5)
	truck.name = "KenneyFireEngine"
	# The engine mesh is unchanged; optional unlocked trim sits on its equipment deck.
	var colors := [Color("f26c52"), Color("35c6ce"), Color("ffd17a"), Color("c6a0e9")]
	var stripe: Color = colors[posmod(skin, colors.size())]
	_box(_stage, Vector3(-2.65, 0.78, 4.85), Vector3(0.8, 0.08, 0.22), stripe)
	for x in [-3.2, -2.95]:
		var beacon := _box(_stage, Vector3(x, 1.1, 4.84), Vector3(0.15, 0.10, 0.22), Color("55d7ee"), true)
		_truck_lights.append(beacon)
	_hose_origin = Vector3(-2.18, 1.06, 4.66)
	var reel := MeshInstance3D.new()
	var reel_mesh := TorusMesh.new()
	reel_mesh.inner_radius = 0.17
	reel_mesh.outer_radius = 0.28
	reel_mesh.rings = 12
	reel_mesh.ring_segments = 8
	reel.mesh = reel_mesh
	reel.material_override = _mat(Color("edd79d"))
	reel.position = Vector3(-2.25, 0.68, 4.55)
	reel.rotation_degrees = Vector3(90, 0, 0)
	_stage.add_child(reel)
	_nozzle = Node3D.new()
	_nozzle.position = _hose_origin
	_stage.add_child(_nozzle)
	var barrel := _box(_nozzle, Vector3(0.0, 0.0, -0.17), Vector3(0.13, 0.13, 0.38), Color("f5cc6b"))
	barrel.name = "ArticulatedHoseNozzle"
	_box(_nozzle, Vector3(0.0, 0.0, -0.36), Vector3(0.18, 0.18, 0.08), Color("354b53"))

func _build_hose() -> void:
	_water_mat = _mat(Color(0.25, 0.82, 0.94, 0.82), true)
	_water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_foam_mat = _mat(Color("d9fcf2"), true)
	for i in range(16):
		var segment := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.055 + float(i) * 0.0018
		mesh.bottom_radius = 0.070 + float(i) * 0.0018
		mesh.height = 1.0
		mesh.radial_segments = 6
		segment.mesh = mesh
		segment.material_override = _water_mat
		segment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_stage.add_child(segment)
		_jet_segments.append(segment)
	for i in range(24):
		var drop := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.048
		sphere.height = 0.14
		sphere.radial_segments = 6
		sphere.rings = 3
		drop.mesh = sphere
		drop.material_override = _foam_mat if i % 3 == 0 else _water_mat
		drop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_stage.add_child(drop)
		_jet_drops.append(drop)
	_splash = _sprite("particles/circle_01.png", 1.4, Color("a6f2f3"))
	_stage.add_child(_splash)
	_aim_ring = _ring(_stage, Vector3(0.0, 0.055, 0.0), 0.96, Color("b9f5f2"))
	_aim_ring.name = "VisibleSprayFootprint"

func _build_cell(cell: Dictionary, index: int) -> void:
	var root := Node3D.new()
	root.name = "Target_%02d_%s" % [index, str(cell.get("kind", "cottage"))]
	root.position = Vector3(float(cell.x), 0.0, float(cell.z))
	_stage.add_child(root)
	var kind := str(cell.get("kind", "cottage"))
	_build_target_lot(root, kind, index)
	var model: Node3D
	match kind:
		"tree":
			model = _model("nature", "tree_pineRoundA" if _theme == 1 else ("tree_default_fall" if _theme == 3 else "tree_oak"), Vector3.ZERO, 0.88, index * 0.73, root)
		"tent":
			model = _model("survival", "tent" if index % 2 == 0 else "tent-canvas", Vector3.ZERO, 1.1, PI if index % 2 else 0.0, root)
		"crates":
			model = _model("survival", "box-large", Vector3(-0.18, 0.0, 0.0), 0.74, 0.1, root)
			_model("survival", "box", Vector3(0.3, 0.0, 0.21), 0.52, -0.1, root)
			_model("survival", "barrel", Vector3(0.23, 0.0, -0.35), 0.37, 0.0, root)
		"shed":
			model = _model("industrial", "building-a" if _theme == 2 else "building-c", Vector3.ZERO, 1.06, 0.0, root)
		"stall":
			model = _model("survival", "tent-canvas", Vector3.ZERO, 1.1, 0.0, root)
			_model("market", "display-fruit" if index % 2 == 0 else "display-bread", Vector3(0.0, 0.0, 0.40), 0.65, 0.0, root)
		_:
			var houses := ["building-type-a", "building-type-b", "building-type-c", "building-type-d"]
			model = _model("suburban", houses[index % houses.size()], Vector3.ZERO, 1.18, 0.0, root)
	var height := float(model.get_meta("fitted_height", 1.0))
	var ring := _ring(root, Vector3(0.0, 0.045, 0.0), 0.72, Color("efbc64"))
	var warning := _ring(root, Vector3(0.0, 0.07, 0.0), 0.88, Color("ffd474"))
	warning.visible = false
	var wet := _sprite("particles/circle_01.png", 1.5, Color(0.15, 0.76, 0.83, 0.0))
	wet.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	wet.rotation_degrees.x = -90.0
	wet.position.y = 0.035
	root.add_child(wet)
	var flames: Array[Sprite3D] = []
	for f in range(3):
		var flame := _sprite("particles/flame_05.png" if f != 1 else "particles/flame_06.png", 0.95, Color("ffab44"))
		flame.region_enabled = true
		flame.region_rect = Rect2(160, 75, 210, 350)
		flame.pixel_size = 0.72 / 210.0
		flame.no_depth_test = true
		flame.position = Vector3((f - 1) * 0.2, height * 0.65 + 0.3, -0.02)
		root.add_child(flame)
		flames.append(flame)
	var smoke := _sprite("particles/smoke_04.png", 1.1, Color(0.24, 0.30, 0.33, 0.35))
	smoke.position.y = height + 0.8
	root.add_child(smoke)
	var steam := _sprite("smoke/whitePuff00.png", 0.85, Color(0.82, 0.98, 1.0, 0.0))
	steam.position.y = height + 0.4
	root.add_child(steam)
	var health_root := Node3D.new()
	health_root.position = Vector3(0.0, height + 0.34, 0.0)
	root.add_child(health_root)
	var health_bg := _quad(health_root, Vector3.ZERO, Vector2(0.82, 0.075), Color("24414a"))
	var health := _quad(health_root, Vector3(0.0, 0.0, 0.004), Vector2(0.74, 0.045), Color("85e3b4"))
	_cells.append({"root": root, "model": model, "height": height, "flames": flames, "smoke": smoke, "steam": steam, "ring": ring, "warning": warning, "wet": wet, "health": health, "health_bg": health_bg, "health_root": health_root, "burned": false, "index": index})

func _build_wind(spec: Dictionary) -> void:
	_wind_marker = Node3D.new()
	_wind_marker.position = Vector3(3.9, 0.0, 4.85)
	_stage.add_child(_wind_marker)
	_box(_wind_marker, Vector3(0.0, 0.8, 0.0), Vector3(0.06, 1.6, 0.06), Color("e8ddbc"))
	var wind: Array = spec.get("wind_dir", [1.0, 0.0])
	var vane := _box(_wind_marker, Vector3(0.18, 1.48, 0.0), Vector3(0.5, 0.15, 0.1), Color("f39a75"))
	vane.rotation.y = -atan2(float(wind[1]), float(wind[0]))

func update_view(run: RefCounted, aim: Vector2, spraying: bool, delta: float) -> void:
	if not is_instance_valid(_stage):
		return
	_run = run
	_time += clampf(delta, 0.0, 0.1)
	if get_viewport().get_visible_rect().size != _last_viewport_size:
		_frame_camera()
	for i in range(mini(_cells.size(), run.cells.size())):
		var state: Dictionary = run.cells[i]
		var visual: Dictionary = _cells[i]
		var heat := clampf(float(state.heat) / 100.0, 0.0, 1.0)
		var moisture := clampf(float(state.wet) / 100.0, 0.0, 1.0)
		var integrity := clampf(float(state.integrity) / 100.0, 0.0, 1.0)
		# run.cells.burned records historical ignition, not destruction.
		var burned := integrity <= 0.0001
		var pulse := sin(_time * 7.3 + i * 1.7)
		for f in range(visual.flames.size()):
			var flame: Sprite3D = visual.flames[f]
			flame.visible = heat > 0.0001
			flame.scale = Vector3.ONE * ((0.34 + heat * 0.95) * (1.0 + 0.08 * sin(_time * (8.0 + f) + i + f)))
			flame.modulate = [Color("f26b36"), Color("ffd16a"), Color("f38d3b")][f]
			flame.position.y = float(visual.height) * 0.70 + 0.25 + heat * 0.25 + f * 0.04
		var smoke: Sprite3D = visual.smoke
		smoke.visible = heat > 0.05
		smoke.modulate.a = heat * 0.32
		smoke.position.y = float(visual.height) + 0.48 + fposmod(_time * 0.24 + i * 0.13, 0.7)
		smoke.position.x = sin(_time * 0.6 + i) * 0.16
		smoke.scale = Vector3.ONE * (0.65 + heat * 0.6)
		var nearby := Vector2(float(state.x), float(state.z)).distance_to(aim) <= float(run.radius) + 0.25
		var steaming := spraying and nearby and (heat > 0.0 or moisture > 0.1)
		var steam: Sprite3D = visual.steam
		steam.visible = steaming or moisture > 0.35
		steam.modulate.a = (0.55 if steaming else 0.12) * (0.8 + 0.2 * pulse)
		steam.scale = Vector3.ONE * (0.75 + 0.2 * sin(_time * 4.0 + i))
		steam.position.y = float(visual.height) + 0.2 + fposmod(_time * 0.38 + i * 0.11, 0.45)
		visual.wet.modulate.a = moisture * 0.34
		var ring_material: StandardMaterial3D = visual.ring.material_override
		ring_material.albedo_color = Color("f5a64c").lerp(Color("ef644b"), heat) if heat > 0.0001 else (Color("657778") if burned else Color("65d1bf"))
		visual.ring.scale = Vector3.ONE * (1.0 + (0.025 * pulse if heat > 0.008 else 0.0))
		var ember_warning := false
		for e in range(int(run.ember_cursor), run.spec.embers.size()):
			var ember: Array = run.spec.embers[e]
			var until := float(ember[0]) - float(run.elapsed)
			if int(ember[1]) == i and until > 0.0 and until <= 3.0:
				ember_warning = true
		visual.warning.visible = ember_warning and not bool(run.done)
		visual.warning.scale = Vector3.ONE * (1.0 + 0.07 * sin(_time * 7.0))
		visual.health.scale.x = maxf(0.015, integrity)
		var health_mat: StandardMaterial3D = visual.health.material_override
		health_mat.albedo_color = Color("7de0b4") if integrity > 0.6 else (Color("ffcc70") if integrity > 0.3 else Color("ed765e"))
		visual.health_root.look_at(camera.global_position)
		visual.health_root.visible = integrity < 0.995 and not burned
		if burned != bool(visual.burned):
			visual.burned = burned
			_apply_burn(visual.model, burned)
	_update_hose(run, aim, spraying)
	for i in range(_truck_lights.size()):
		var mat: StandardMaterial3D = _truck_lights[i].material_override
		mat.albedo_color = Color("89f4ff") if sin(_time * 7.0 + i * PI) > 0 else Color("2394aa")

func _update_hose(run: RefCounted, aim: Vector2, spraying: bool) -> void:
	var endpoint := Vector3(aim.x, 0.12, aim.y)
	for i in range(mini(_cells.size(), run.cells.size())):
		var cell: Dictionary = run.cells[i]
		if Vector2(float(cell.x), float(cell.z)).distance_to(aim) < 0.56:
			endpoint.y = minf(float(_cells[i].height) * 0.65, 1.1)
			break
	_nozzle.look_at(endpoint)
	_aim_ring.position = Vector3(aim.x, 0.065, aim.y)
	_aim_ring.scale = Vector3.ONE * float(run.radius) / 0.96
	_aim_ring.visible = spraying
	var active := spraying and float(run.water) > 0.01 and not bool(run.done)
	var length := _hose_origin.distance_to(endpoint)
	var lift := clampf(length * 0.23, 0.40, 2.05)
	for i in range(_jet_segments.size()):
		var segment := _jet_segments[i]
		segment.visible = active
		if active:
			var a := _water_point(float(i) / _jet_segments.size(), endpoint, lift)
			var b := _water_point(float(i + 1) / _jet_segments.size(), endpoint, lift)
			_segment_between(segment, a, b)
	for i in range(_jet_drops.size()):
		var drop := _jet_drops[i]
		drop.visible = active
		if active:
			var t := fposmod(_time * 1.6 + float(i) / _jet_drops.size(), 1.0)
			drop.position = _water_point(t, endpoint, lift) + Vector3(sin(i * 2.4) * 0.15 * t, sin(i * 4.1 + _time * 12) * 0.11 * t, cos(i * 2.3) * 0.15 * t)
	_splash.visible = active
	_splash.position = endpoint + Vector3(0.0, 0.13, 0.0)
	_splash.scale = Vector3.ONE * (0.65 + 0.12 * sin(_time * 19.0))

func _water_point(t: float, endpoint: Vector3, lift: float) -> Vector3:
	var point := _hose_origin.lerp(endpoint, t)
	point.y += sin(t * PI) * lift
	point.x += sin(t * PI) * 0.20 + sin(t * 18.0 - _time * 18.0) * 0.018
	return point

func _build_target_lot(root: Node3D, kind: String, index: int) -> void:
	if kind == "tree":
		var soil := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.49
		mesh.bottom_radius = 0.52
		mesh.height = 0.025
		mesh.radial_segments = 9
		soil.mesh = mesh
		soil.position.y = 0.015
		soil.rotation.y = index * 0.9
		soil.material_override = _mat(Color("877751") if _theme == 3 else Color("4c765e"))
		root.add_child(soil)
		_model("nature", "plant_bushSmall", Vector3(0.42, 0.0, 0.29), 0.24, 0.0, root)
		_model("nature", "rock_smallA", Vector3(-0.37, 0.0, 0.33), 0.18, index, root)
	elif kind == "cottage":
		_box(root, Vector3(0.0, 0.012, 0.0), Vector3(1.42, 0.02, 1.40), Color("89a56e"))
		_box(root, Vector3(0.0, 0.026, 0.58), Vector3(0.28, 0.025, 0.50), Color("d4c49e"))
		_model("suburban", "planter", Vector3(-0.55, 0.0, 0.47), 0.25, 0.0, root)
		_model("nature", "plant_bushSmall", Vector3(0.57, 0.0, 0.4), 0.30, index, root)
	elif kind == "shed":
		_box(root, Vector3(0.0, 0.012, 0.0), Vector3(1.38, 0.02, 1.37), Color("b2b7a3"))
		for j in range(3):
			_box(root, Vector3(-0.35 + j * 0.33, 0.03, 0.63), Vector3(0.19, 0.018, 0.08), Color("d8b75f"))
		_model("car", "cone", Vector3(0.61, 0.0, 0.56), 0.16, 0.0, root)
	elif kind == "crates":
		_box(root, Vector3(0.0, 0.013, 0.0), Vector3(1.30, 0.022, 1.24), Color("a68e6c"))
		_model("survival", "resource-planks", Vector3(-0.38, 0.0, 0.48), 0.39, 0.0, root)
	else:
		_box(root, Vector3(0.0, 0.012, 0.0), Vector3(1.42, 0.02, 1.42), Color("a69f70") if kind == "tent" else Color("cfb891"))
		_model("survival", "bucket", Vector3(-0.53, 0.0, 0.45), 0.22, 0.0, root)
		_model("nature", "rock_smallB", Vector3(0.52, 0.0, 0.53), 0.18, index, root)

func world_from_screen(screen: Vector2) -> Vector2:
	if not is_instance_valid(camera):
		return Vector2.ZERO
	# A visible roof/flame is part of the same hit target as its ground ring.
	# This resolves perspective parallax without changing the model's spray radius.
	var closest := 33.0 * get_viewport().get_visible_rect().size.x / 540.0
	var snap := Vector2(INF, INF)
	for visual in _cells:
		var root: Node3D = visual.root
		var roof := camera.unproject_position(root.global_position + Vector3(0.0, minf(float(visual.height) * 0.7, 1.15), 0.0))
		var distance := screen.distance_to(roof)
		if distance < closest:
			closest = distance
			snap = Vector2(root.position.x, root.position.z)
	if is_finite(snap.x):
		return snap
	var origin := camera.project_ray_origin(screen)
	var direction := camera.project_ray_normal(screen)
	if absf(direction.y) < 0.0001:
		return Vector2.ZERO
	var point := origin + direction * (-origin.y / direction.y)
	return Vector2(clampf(point.x, -4.15, 4.15), clampf(point.z, -4.55, 4.25))

func screen_from_world(point: Vector2) -> Vector2:
	return camera.unproject_position(Vector3(point.x, 0.0, point.y)) if is_instance_valid(camera) else Vector2.ZERO

func _model(pack: String, asset: String, position_: Vector3, width: float, yaw: float = 0.0, parent: Node3D = null) -> Node3D:
	var path := ROOT + str(MODEL_DIR[pack]) + asset + ".glb"
	if not _scenes.has(path):
		_scenes[path] = load(path)
	var holder := Node3D.new()
	holder.name = asset.validate_node_name()
	(parent if parent != null else _stage).add_child(holder)
	holder.position = position_
	holder.rotation.y = yaw
	var packed: PackedScene = _scenes[path]
	if packed == null:
		push_error("Missing selected Kenney model: " + path)
		return holder
	var imported := packed.instantiate() as Node3D
	var fitting := Node3D.new()
	holder.add_child(fitting)
	fitting.add_child(imported)
	if not _bounds_cache.has(path):
		var boxes: Array[AABB] = []
		_collect_bounds(imported, Transform3D.IDENTITY, boxes)
		var bounds := AABB(Vector3.ZERO, Vector3.ZERO)
		for i in range(boxes.size()):
			bounds = boxes[i] if i == 0 else bounds.merge(boxes[i])
		_bounds_cache[path] = bounds
	var bounds: AABB = _bounds_cache[path]
	var denominator := maxf(maxf(bounds.size.x, bounds.size.z), 0.001)
	var factor := width / denominator
	# Keep unusually tall models visually legible without covering adjacent cells.
	if bounds.size.y * factor > width * 1.75:
		factor = width * 1.75 / maxf(bounds.size.y, 0.001)
	fitting.scale = Vector3.ONE * factor
	fitting.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * factor
	holder.set_meta("fitted_height", bounds.size.y * factor)
	holder.set_meta("original_bounds", bounds)
	return holder

func _collect_bounds(node: Node, inherited: Transform3D, boxes: Array[AABB]) -> void:
	var combined := inherited
	if node is Node3D:
		combined = inherited * (node as Node3D).transform
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		boxes.append(combined * (node as MeshInstance3D).mesh.get_aabb())
	for child in node.get_children():
		_collect_bounds(child, combined, boxes)

func _mat(color: Color, unshaded: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	if unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if color.a < 0.999:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material

func _box(parent: Node3D, position_: Vector3, size: Vector3, color: Color, unshaded: bool = false) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = position_
	instance.material_override = _mat(color, unshaded)
	parent.add_child(instance)
	return instance

func _quad(parent: Node3D, position_: Vector3, size: Vector2, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = position_
	var material := _mat(color, true)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	return instance

func _ring(parent: Node3D, position_: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - 0.035
	mesh.outer_radius = radius
	mesh.rings = 24
	mesh.ring_segments = 4
	instance.mesh = mesh
	instance.position = position_
	instance.material_override = _mat(color, true)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	return instance

func _sprite(relative_path: String, width: float, tint: Color) -> Sprite3D:
	if not _textures.has(relative_path):
		_textures[relative_path] = load(ROOT + relative_path)
	var sprite := Sprite3D.new()
	sprite.texture = _textures[relative_path]
	sprite.pixel_size = width / maxf(float(sprite.texture.get_width()), 1.0)
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.no_depth_test = false
	sprite.shaded = false
	sprite.modulate = tint
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return sprite

func _segment_between(segment: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var direction := b - a
	var distance := direction.length()
	segment.position = (a + b) * 0.5
	segment.scale = Vector3(1.0, maxf(distance, 0.001), 1.0)
	var up := direction.normalized()
	var right := up.cross(Vector3.FORWARD)
	if right.length_squared() < 0.0001:
		right = up.cross(Vector3.RIGHT)
	right = right.normalized()
	segment.basis = Basis(right, up, right.cross(up)).scaled(Vector3(1.0, maxf(distance, 0.001), 1.0))

func _apply_burn(node: Node, burned: bool) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_overlay = _mat(Color(0.12, 0.15, 0.16, 0.78)) if burned else null
	for child in node.get_children():
		_apply_burn(child, burned)

func _lantern(position_: Vector3) -> void:
	var holder := Node3D.new()
	holder.position = position_
	_stage.add_child(holder)
	_box(holder, Vector3(0.0, 0.85, 0.0), Vector3(0.07, 1.7, 0.07), Color("486064"))
	_box(holder, Vector3(0.0, 1.69, 0.0), Vector3(0.28, 0.10, 0.28), Color("486064"))
	_box(holder, Vector3(0.0, 1.48, 0.0), Vector3(0.20, 0.30, 0.20), Color("ffe4a5"), true)
	if _theme == 5:
		var light := OmniLight3D.new()
		light.position = Vector3(0.0, 1.4, 0.0)
		light.light_color = Color("ffcb7e")
		light.light_energy = 0.48
		light.omni_range = 2.8
		holder.add_child(light)

func _bunting(a: Vector3, b: Vector3) -> void:
	for p in [a, b]:
		_box(_stage, p * Vector3(1.0, 0.5, 1.0), Vector3(0.06, p.y, 0.06), Color("6f6b61"))
	for i in range(14):
		var t0 := float(i) / 14.0
		var t1 := float(i + 1) / 14.0
		var p0 := a.lerp(b, t0) - Vector3(0.0, sin(t0 * PI) * 0.28, 0.0)
		var p1 := a.lerp(b, t1) - Vector3(0.0, sin(t1 * PI) * 0.28, 0.0)
		var rope := MeshInstance3D.new()
		var rope_mesh := CylinderMesh.new()
		rope_mesh.top_radius = 0.012
		rope_mesh.bottom_radius = 0.012
		rope_mesh.height = 1.0
		rope_mesh.radial_segments = 5
		rope.mesh = rope_mesh
		rope.material_override = _mat(Color("ddc895"))
		_stage.add_child(rope)
		_segment_between(rope, p0, p1)
	for i in range(13):
		var t := float(i + 1) / 14.0
		var p := a.lerp(b, t) - Vector3(0.0, sin(t * PI) * 0.28, 0.0)
		var flag := MeshInstance3D.new()
		var flag_mesh := ArrayMesh.new()
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3(-0.17, 0.0, 0.0), Vector3(0.17, 0.0, 0.0), Vector3(0.0, -0.33, 0.0)])
		arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.FORWARD, Vector3.FORWARD, Vector3.FORWARD])
		flag_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		flag.mesh = flag_mesh
		flag.position = p
		var material := _mat([Color("f29b7d"), Color("f5d994"), Color("73c9c4")][i % 3], true)
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		flag.material_override = material
		_stage.add_child(flag)
