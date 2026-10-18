extends SceneTree

class Gallery extends Node2D:
	const Art = preload("res://scripts/pixel_art.gd")
	const Data = preload("res://scripts/game_data.gd")
	func _draw() -> void:
		draw_rect(Rect2(0,0,1440,1120),Color("142a37"))
		var font: Font = preload("res://assets/fonts/NotoSansCJK-Regular.ttc")
		draw_string(font,Vector2(20,28),"TIDEBOUND / 108 种灵兽 · 实际游戏图集预览",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("f4dcaa"))
		for form in range(12):
			for family in range(9):
				var id := form*9+family
				var origin := Vector2(form*120,40+family*120)
				if (form+family)%2 == 0: draw_rect(Rect2(origin,Vector2(120,120)),Color("1b3543"))
				Art.draw_creature(self,origin+Vector2(60,50),id,0.88,0)
				draw_string(font,origin+Vector2(5,111),"%03d %s" % [id+1,Data.SPECIES[id].name],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("e8e4cb"))

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://build")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1440,1120)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var gallery := Gallery.new()
	viewport.add_child(gallery)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var result := viewport.get_texture().get_image().save_png("res://build/all-pets-v0.7.png")
	viewport.queue_free()
	await process_frame
	preload("res://scripts/pixel_art.gd").texture_cache.clear()
	await create_timer(0.2).timeout
	print("GALLERY RESULT: ",result)
	quit(0 if result == OK else 1)
