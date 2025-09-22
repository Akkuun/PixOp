extends Node

var base_path = "res://Lib_Images/Shaders/"

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

func apply_shader_to_image(img: Image, shader_material: ShaderMaterial) -> Image:
	# create a temporary Sprite2D to apply the shader and get the image
	var temp_sprite := Sprite2D.new()
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
	
	# Workaround for web export, since compute shaders are not available here
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	var img_result := viewport.get_texture().get_image()
	viewport.queue_free()
	return img_result

func apply_shader_to_two_images(img1: Image, img2: Image, shader_material: ShaderMaterial) -> Image:
	var width = min(img1.get_width(), img2.get_width())
	var height = min(img1.get_height(), img2.get_height())
	
	var temp_sprite := Sprite2D.new()
	temp_sprite.material = shader_material
	var tex1 := ImageTexture.create_from_image(img1)
	temp_sprite.texture = tex1
	temp_sprite.position = Vector2(width / 2.0, height / 2.0)
	
	var tex2 := ImageTexture.create_from_image(img2)
	shader_material.set_shader_parameter("other_image", tex2)
	
	var viewport := SubViewport.new()
	viewport.size = Vector2(width, height)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.add_child(temp_sprite)
	get_tree().current_scene.add_child(viewport)
	
	# Workaround for web export, since compute shaders are not available here
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	var img_result := viewport.get_texture().get_image()
	viewport.queue_free()
	return img_result

func flou(img: Image, kernel_size: int) -> Image:
	var shader_material := getShader(base_path + "flou.gdshader")
	shader_material.set_shader_parameter("kernel_size", float(kernel_size))
	return await apply_shader_to_image(img, shader_material)

func dilatation(img: Image, kernel_size: int) -> Image:
	var shader_material = getShader(base_path + "dilatation.gdshader")
	shader_material.set_shader_parameter("kernel_size", float(kernel_size))
	return await apply_shader_to_image(img, shader_material)

func erosion(img: Image, kernel_size: int) -> Image:
	var shader_material = getShader(base_path + "erosion.gdshader")
	shader_material.set_shader_parameter("kernel_size", float(kernel_size))
	return await apply_shader_to_image(img, shader_material)

func negatif(img: Image) -> Image:
	var shader_material = getShader(base_path + "negatif.gdshader")
	return await apply_shader_to_image(img, shader_material)

func seuil(img: Image, colors: Array) -> Image:
	var shader_material = getShader(base_path + "seuil.gdshader")
	var n_colors = colors.size()
	shader_material.set_shader_parameter("n_colors", n_colors)

	var padded_colors = colors.duplicate()
	while padded_colors.size() < 8:
		padded_colors.append(Color(0,0,0,1))
	shader_material.set_shader_parameter("colors", padded_colors)
	return await apply_shader_to_image(img, shader_material)

func flou_fond(input: Image, carte_verite: Image, kernel_size: int) -> Image:
	var shader_material = getShader(base_path + "flou_fond.gdshader")
	shader_material.set_shader_parameter("kernel_size", float(kernel_size))
	return await apply_shader_to_two_images(input, carte_verite, shader_material)

# Met tous les pixels différents à 0
func difference(input: Image, img: Image) -> Image:
	var shader_material = getShader(base_path + "difference.gdshader")
	return await apply_shader_to_two_images(input, img, shader_material)
