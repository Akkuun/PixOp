extends Node

var base_path = "res://Lib_Images/Shaders/"

var rd: RenderingDevice

var shader_rids = {}
var pipelines = {}
var img_in_rid: RID
var img_out_rid: RID
var uniform_set: RID

class Histogram:
	var red: Array
	var green: Array
	var blue: Array

	func _init():
		red = []
		green = []
		blue = []
		for i in range(256):
			red.append(0)
			green.append(0)
			blue.append(0)

func getHistogram(image: Image) -> Histogram:
	var histogram = Histogram.new()
	var width = image.get_width()
	var height = image.get_height()
	
	for x in range(width):
		for y in range(height):
			var color = image.get_pixel(x, y)
			histogram.red[int(color.r * 255)] += 1
			histogram.green[int(color.g * 255)] += 1
			histogram.blue[int(color.b * 255)] += 1
	
	return histogram
	

func PSNR(img1: Image, img2: Image) -> float:
	var mse = 0.0
	var width = img1.get_width()
	var height = img1.get_height()
	
	for x in range(width):
		for y in range(height):
			var color1 = img1.get_pixel(x, y)
			var color2 = img2.get_pixel(x, y)
			mse += pow(color1.r - color2.r, 2)
			mse += pow(color1.g - color2.g, 2)
			mse += pow(color1.b - color2.b, 2)
	
	mse /= (width * height * 3)
	
	if mse == 0:
		return 10000.0  # Images are identical
	
	var psnr = 10 * log(1.0 / mse) / log(10)
	return psnr

func getShader(path: String) -> ShaderMaterial:
	var shader = load(path)
	var shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	return shader_material

func flou(img: Image, kernel_size: int) -> Image:
	# create a temporary Sprite2D to apply the shader and get the image
	var temp_sprite := Sprite2D.new()
	var shader_material := getShader(base_path + "flou.gdshader")
	shader_material.set_shader_parameter("kernel_size", float(kernel_size))
	temp_sprite.material = shader_material
	var tex := ImageTexture.create_from_image(img)
	temp_sprite.texture = tex
	temp_sprite.position = Vector2(img.get_width() / 2.0, img.get_height() / 2.0)
	
	var viewport := SubViewport.new()
	viewport.size = Vector2(img.get_width(), img.get_height())
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.add_child(temp_sprite)
	get_tree().current_scene.add_child(viewport)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var img_result := viewport.get_texture().get_image()
	viewport.queue_free()
	return img_result

func dilatation(kernel_size: int) -> ShaderMaterial:
	var shader_material = getShader(base_path + "dilatation.gdshader")
	shader_material.set_shader_parameter("kernel_size", float(kernel_size))
	return shader_material

func erosion(kernel_size: int) -> ShaderMaterial:
	var shader_material = getShader(base_path + "erosion.gdshader")
	shader_material.set_shader_parameter("kernel_size", float(kernel_size))
	return shader_material

func negatif() -> ShaderMaterial:
	return getShader(base_path + "negatif.gdshader")

# takes 8 colors at max
func seuil(colors: Array) -> ShaderMaterial:
	var shader_material = getShader(base_path + "seuil.gdshader")
	var n_colors = colors.size()
	shader_material.set_shader_parameter("n_colors", n_colors)

	var padded_colors = colors.duplicate()
	while padded_colors.size() < 8:
		padded_colors.append(Color(0,0,0,1))
	shader_material.set_shader_parameter("colors", padded_colors)
	return shader_material

# Met tous les pixels différents à 0
func difference(input: Image, img: Image) -> Image:
	var width = input.get_width()
	var height = input.get_height()
	var result = Image.create(width, height, false, Image.FORMAT_RGBA8)
	for x in range(width):
		for y in range(height):
			var c1 = input.get_pixel(x, y)
			var c2 = img.get_pixel(x, y)
			if c1 == c2:
				result.set_pixel(x, y, c1)
			else:
				result.set_pixel(x, y, Color(0, 0, 0, 0))
	return result
