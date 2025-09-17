extends Node

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

func erosion(img: Image, kernel_size: int) -> Image:
	var width = img.get_width()
	var height = img.get_height()
	var result = Image.new()
	result.create(width, height, false, img.get_format())
	
	var offset = round(kernel_size / 2)
	
	for x in range(width):
		for y in range(height):
			var min_val = 1.0
			for kx in range(-offset, offset + 1):
				for ky in range(-offset, offset + 1):
					var nx = clamp(x + kx, 0, width - 1)
					var ny = clamp(y + ky, 0, height - 1)
					var color = img.get_pixel(nx, ny)
					min_val = min(min_val, color.r)  # Assuming grayscale image
			result.set_pixel(x, y, Color(min_val, min_val, min_val))
	
	return result

func flou(img: Image, kernel_size: int) -> ShaderMaterial:
	var shader = load("res://Shaders/flou.gdshader")
	var shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	shader_material.set_shader_parameter("kernel_size", kernel_size)
	return shader_material

func flou2(img: Image, kernel_size: int) -> Image:
	var width = img.get_width()
	var height = img.get_height()
	var result = Image.create(width, height, false, img.get_format())
	
	var offset = round(kernel_size / 2)
	
	for x in range(width):
		for y in range(height):
			var sumR = 0.0
			var sumG = 0.0
			var sumB = 0.0
			var count = 0
			for kx in range(max(0,-offset), min(offset + 1, width - 1)):
				if kx >= 0 and kx < width:
					for ky in range(max(0,-offset), min(offset + 1, height - 1)):
						if ky >= 0 and ky < height:
							var nx = clamp(x + kx, 0, width - 1)
							var ny = clamp(y + ky, 0, height - 1)
							var color = img.get_pixel(nx, ny)
							sumR += color.r
							sumG += color.g
							sumB += color.b
							count += 1
			var avgR = sumR / count
			var avgG = sumG / count
			var avgB = sumB / count
			result.set_pixel(x, y, Color(avgR, avgG, avgB))

	return result
