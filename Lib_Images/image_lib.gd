extends Node

var base_path = "res://Lib_Images/Shaders/"

class HistogramRGB:
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

func getHistogramRGB(image: Image) -> HistogramRGB:
	var histogram = HistogramRGB.new()
	var width = image.get_width()
	var height = image.get_height()
	
	for x in range(width):
		for y in range(height):
			var color = image.get_pixel(x, y)
			histogram.red[int(color.r * 255)] += 1
			histogram.green[int(color.g * 255)] += 1
			histogram.blue[int(color.b * 255)] += 1
	
	return histogram

func getHistogramGrayscale(imageGreyscale: Image) -> Array:
	var histogram = []
	for i in range(256):
		histogram.append(0.0)

	var width = imageGreyscale.get_width()
	var height = imageGreyscale.get_height()

	for x in range(width):
		for y in range(height):
			var color = imageGreyscale.get_pixel(x, y)
			var gray = int(color.r * 255)
			histogram[gray] += 1.0

	return histogram

func compute_first_order_cumulative_moment(hist: Array, k: int) -> float:
	var focm : float = 0.0
	for i in range(k + 1):  # Include k
		focm += float(i) * hist[i]
	return focm

func compute_zero_order_cumulative_moment(hist: Array, k: int) -> float:
	var zocm : float = 0.0
	for i in range(k + 1):  # Include k
		zocm += hist[i]
	return zocm

func compute_variance_class_separability(uT: float, wk: float, uk: float) -> float:
	if wk == 0.0 or wk == 1.0:
		return 0.0
	return pow(uT * wk - uk, 2) / (wk * (1.0 - wk))

func otsu(imageGreyscale: Image) -> Color:
	var hist = getHistogramGrayscale(imageGreyscale)
	var total_pixels = imageGreyscale.get_width() * imageGreyscale.get_height()
	
	# Normalize histogram
	var hist_normalized = []
	for i in range(256):
		hist_normalized.append(hist[i] / float(total_pixels))

	# Compute global mean
	var uT = 0.0
	for i in range(256):
		uT += float(i) * hist_normalized[i]

	var var_class_sep_max : float = 0.0
	var best_threshold : int = 0

	for t in range(1, 255):
		# Class 1: [0, t]
		var w1 = compute_zero_order_cumulative_moment(hist_normalized, t)
		var u1 = 0.0
		if w1 > 0.0:
			u1 = compute_first_order_cumulative_moment(hist_normalized, t) / w1
		
		# Class 2: [t+1, 255]
		var w2 = 1.0 - w1
		var u2 = 0.0
		if w2 > 0.0:
			u2 = (uT - compute_first_order_cumulative_moment(hist_normalized, t)) / w2
		
		# Between-class variance
		var var_between = w1 * w2 * pow(u1 - u2, 2)
		
		if var_between > var_class_sep_max:
			var_class_sep_max = var_between
			best_threshold = t

	return Color(float(best_threshold) / 255.0, float(best_threshold) / 255.0, float(best_threshold) / 255.0, 1.0)	


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
		return 200.0  # Images are identical
	
	var psnr = 10 * log(255*255 / mse) / log(10)
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

func expansion_dynamique(img: Image) -> Image:
	var histo = getHistogramRGB(img)
	var mins = [0, 0, 0]
	var maxs = [255, 255, 255]
	for c in range(3):
		# Trouver le minimum non nul
		for i in range(256):
			if c == 0 and histo.red[i] > 0:
				mins[0] = i
				break
			elif c == 1 and histo.green[i] > 0:
				mins[1] = i
				break
			elif c == 2 and histo.blue[i] > 0:
				mins[2] = i
				break
		# Trouver le maximum non nul
		for i in range(255, -1, -1):
			if c == 0 and histo.red[i] > 0:
				maxs[0] = i
				break
			elif c == 1 and histo.green[i] > 0:
				maxs[1] = i
				break
			elif c == 2 and histo.blue[i] > 0:
				maxs[2] = i
				break

	var betas = [255.0 / (maxs[0] - mins[0]), 255.0 / (maxs[1] - mins[1]), 255.0 / (maxs[2] - mins[2])]
	var alphas = [-mins[0] * betas[0], -mins[1] * betas[1], -mins[2] * betas[2]]

	return await expansion_dynamique_shader(img, alphas, betas)

func expansion_dynamique_shader(img: Image, alphas: Array, betas: Array) -> Image:
	var shader_material = getShader(base_path + "expansion_dynamique.gdshader")
	shader_material.set_shader_parameter("alphas", alphas)
	shader_material.set_shader_parameter("betas", betas)
	return await apply_shader_to_image(img, shader_material)

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

func ouverture(img: Image, kernel_size: int) -> Image:
	var eroded_img = await erosion(img, kernel_size)
	return await dilatation(eroded_img, kernel_size)

func fermeture(img: Image, kernel_size: int) -> Image:
	var dilated_img = await dilatation(img, kernel_size)
	return await erosion(dilated_img, kernel_size)

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

func seuil_otsu(img: Image) -> Image:
	var gray_img = await greyscale(img)
	var threshold_color = otsu(gray_img)
	return await seuil(gray_img, [threshold_color])

func flou_fond(input: Image, carte_verite: Image, kernel_size: int) -> Image:
	var shader_material = getShader(base_path + "flou_fond.gdshader")
	shader_material.set_shader_parameter("kernel_size", float(kernel_size))
	return await apply_shader_to_two_images(input, carte_verite, shader_material)

func greyscale(input: Image) -> Image:
	var shader_material = getShader(base_path + "greyscale.gdshader")
	return await apply_shader_to_image(input, shader_material)

# Met tous les pixels différents à 0
func difference(input: Image, img: Image) -> Image:
	var shader_material = getShader(base_path + "difference.gdshader")
	return await apply_shader_to_two_images(input, img, shader_material)
