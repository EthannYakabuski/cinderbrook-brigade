extends SceneTree
## Geometry/visibility/input projection regression. Does not load or edit a profile.
## Run with process-isolated user data, as with the other application tests.
const World = preload("res://game/world.gd")
const Run = preload("res://game/run.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("WORLD FAIL " + label)

func _run() -> void:
	for profile in [Vector2i(540,960), Vector2i(800,1280), Vector2i(1200,1600)]:
		root.size = profile
		root.content_scale_size = profile
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		await process_frame
		for theme in range(6):
			var run := Run.new()
			run.start(9000 + theme, "campaign", theme * 6 + 5, {}, 0)
			var world := World.new()
			root.add_child(world)
			world.build(run, theme % 4)
			await process_frame
			world.update_view(run, Vector2(float(run.cells[0].x),float(run.cells[0].z)), true, 1.0/60.0)
			_check(world._cells.size() == run.cells.size(), "stable visual cell indexing")
			for i in range(run.cells.size()):
				var visual: Dictionary = world._cells[i]
				var cell: Dictionary = run.cells[i]
				var height := float(visual.height)
				_check(height > 0.05 and height < 2.5, "measured model bounds")
				var roof := world.camera.unproject_position(visual.root.global_position + Vector3(0.0,minf(height*0.7,1.15),0.0))
				var hit := world.world_from_screen(roof)
				_check(hit.distance_to(Vector2(float(cell.x),float(cell.z))) < 0.001, "visible target maps to simulation center")
				_check(roof.y > profile.y*0.16 and roof.y < profile.y*0.79 and roof.x > profile.x*0.015 and roof.x < profile.x*0.985, "phone/tablet HUD-safe target projection")
				if float(cell.heat) > 1.0:
					_check(visual.flames[0].visible, "historically ignited active fire remains visible")
			_check(world._jet_segments[0].visible, "positive water displays held spray")
			run.water = 0.0
			world.update_view(run, Vector2.ZERO, true, 0.0)
			_check(not world._jet_segments[0].visible, "empty tank never shows false flowing water")
			run.water = 100.0
			world.update_view(run, Vector2.ZERO, false, 0.0)
			_check(not world._jet_segments[0].visible and not world._aim_ring.visible, "released touch removes stream and spray footprint")
			run.cells[0].heat = 60.0
			run.cells[0].integrity = 0.0
			world.update_view(run, Vector2.ZERO, false, 0.0)
			_check(world._cells[0].flames[0].visible and world._cells[0].smoke.visible, "destroyed hot object stays an obvious cooling target")
			run.cells[0].heat = 0.0
			world.update_view(run, Vector2.ZERO, false, 0.0)
			_check(not world._cells[0].flames[0].visible, "cooled object no longer displays flames")
			run.spec.embers = [[run.elapsed+2.0,0,60.0]]
			run.ember_cursor = 0
			world.update_view(run, Vector2.ZERO, false, 0.0)
			_check(world._cells[0].warning.visible, "imminent ember gets gold warning ring")
			run.done = true
			world.update_view(run, Vector2.ZERO, true, 0.0)
			_check(not world._jet_segments[0].visible and not world._cells[0].warning.visible, "ended run has no flowing water or future warning")
			root.remove_child(world)
			world.queue_free()
			await process_frame
	print("WORLD %s checks=%d failures=%d" % ["PASS" if failures == 0 else "FAIL",checks,failures])
	quit(0 if failures == 0 else 1)
