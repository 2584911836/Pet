extends RefCounted
# Original AI-generated world atlas; unmodified source pixels, explicit regions.
const REGIONS = [Rect2(21,9,396,388), Rect2(484,114,308,245), Rect2(890,82,342,318), Rect2(27,479,382,336), Rect2(466,370,332,513), Rect2(931,457,284,393), Rect2(101,881,254,328), Rect2(459,889,323,341), Rect2(846,955,376,254)]
static var cache: Dictionary = {}

static func texture(id: int) -> Texture2D:
	if not cache.has(id):
		var atlas := AtlasTexture.new()
		atlas.atlas = load("res://assets/art/world_objects.png")
		atlas.region = REGIONS[id]
		atlas.filter_clip = true
		cache[id] = atlas
	return cache[id]

static func draw_object(canvas: CanvasItem, id: int, anchor: Vector2, maximum: Vector2, tint: Color = Color.WHITE) -> void:
	var sprite := texture(id)
	var factor := minf(maximum.x/sprite.get_width(),maximum.y/sprite.get_height())
	var size := sprite.get_size()*factor
	canvas.draw_texture_rect(sprite,Rect2(anchor-Vector2(size.x*0.5,size.y),size),false,tint)
