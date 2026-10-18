extends SceneTree

const Data = preload("res://scripts/game_data.gd")
const Art = preload("res://scripts/pixel_art.gd")
var failures := 0
var checks := 0

func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL CATALOG: "+text)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://build")
	var ignore := FileAccess.open("res://build/.gdignore",FileAccess.WRITE)
	ignore.close()
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.close_modal()
	var names: Dictionary = {}
	var silhouettes: Dictionary = {}
	var images: Dictionary = {}
	var reachable: Dictionary = {}
	var atlas := Image.create(480,324,false,Image.FORMAT_RGBA8)
	atlas.fill(Color("192f3d"))
	check(Data.SPECIES.size() >= 100,"at least 100 species")
	for id in range(Data.SPECIES.size()):
		var species: Dictionary = Data.SPECIES[id]
		check(not names.has(species.name),"unique name "+str(id))
		names[species.name] = true
		check(int(species.type) >= 0 and int(species.type) < 3,"valid element "+str(id))
		check(not str(species.skill).is_empty() and not str(species.lore).is_empty(),"skill and ecology "+str(id))
		check(game.valid_creature(game.creature(id)),"valid runtime creature "+str(id))
		var portrait: Texture2D = Art.portrait(id)
		check(portrait is AtlasTexture and portrait.atlas.resource_path.contains("/species_"),"uses redesigned species art, never old template fallback %d" % id)
		var image: Image = Art.sprite_image(id)
		var pixels := image.get_data()
		var rgba_hash := pixels.hex_encode().sha256_text()
		check(not images.has(rgba_hash),"unique rendered sprite "+str(id))
		images[rgba_hash] = true
		var alpha := PackedByteArray()
		for y in range(image.get_height()):
			for x in range(image.get_width()): alpha.append(1 if image.get_pixel(x,y).a > 0 else 0)
		var silhouette_hash := alpha.hex_encode().sha256_text()
		check(not silhouettes.has(silhouette_hash),"unique silhouette, not palette-only "+str(id))
		silhouettes[silhouette_hash] = true
		atlas.blit_rect(image,Rect2i(0,0,40,36),Vector2i((id%12)*40,int(id/12)*36))
	for island in range(3):
		for region in range(3):
			var residents: Dictionary = {}
			for phase in range(2):
				var pool: Array = game.encounter_pool(island,region,phase)
				check(not pool.is_empty(),"nonempty encounter pool")
				for id in pool:
					reachable[id] = true
					residents[id] = true
			check(residents.size() == 12,"twelve species per region")
	check(reachable.size() == 108,"all 108 species reachable through wild encounters")
	game.known = range(108)
	game.party = [game.creature(107)]
	game.active = 0
	game.reserve = []
	for id in range(107): game.reserve.append(game.creature(id))
	game.save_game(false)
	game.known = [0]
	game.reserve = []
	game.load_game()
	check(game.discovered() == 108 and game.reserve.size() == 107 and game.party[0].species == 107,"full 108-species collection survives save round-trip")
	if DirAccess.dir_exists_absolute("res://build"):
		check(atlas.save_png("res://build/pet-atlas-v0.4.png") == OK,"atlas artifact written")
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	print("CATALOG RESULT: %d checks, %d failures; %d names, %d unique RGBA sprites, %d unique alpha silhouettes" % [checks,failures,names.size(),images.size(),silhouettes.size()])
	quit(1 if failures else 0)
