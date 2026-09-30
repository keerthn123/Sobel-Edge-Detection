from PIL import Image
import numpy as np

img_path = "C:\\SOBEL_PROJECT\\Input\\imagesrcfile.jpg"  
image = Image.open(img_path)
print('Original Image Size:', image.size)
print('Original Image Mode:', image.mode)
## Convert the image to grayscale
G_image = image.convert('L')
G_image.save("../Gray_image.png")
print("Gray_image.png created successfully!")

## Resize the grayscale image to 100x100 pixels
G_image = G_image.resize((100, 100))
G_image.save("../Gray_image_resized.png")
print("Gray_image_resized.png created successfully!")


print('Grayscale Image Size:', G_image.size)
print('Grayscale Image Mode:', G_image.mode)
first_pixel = G_image.getpixel((0, 0))
print('First pixel value:', first_pixel)
print("Pixel at (1, 0):", G_image.getpixel((1, 0))) ## Get the pixel at (1, 0)
print("Pixel at (2, 0):", G_image.getpixel((2, 0))) ### Get the pixel at (2, 0)
print("Pixel at (0, 1):", G_image.getpixel((0, 1))) # ## Get the pixel at (0, 1)
first_pixel = G_image.getpixel((0, 0))
binary_pixel = format(first_pixel, '08b')
print("First pixel decimal:", first_pixel)
print("First pixel binary:", binary_pixel)
# Create imagesrc.txt
with open("../imagesrc.txt", "w") as file:
    for y in range(100):
        for x in range(100):
            pixel = G_image.getpixel((x, y))
            binary_pixel = format(pixel, '08b')
            file.write(binary_pixel + "\n")
print("imagesrc.txt created successfully!")

# Sobel horizontal kernel
Kx = np.array([
    [-1,  0,  1],
    [-2,  0,  2],
    [-1,  0,  1]
])

# Sobel vertical kernel
Ky = np.array([
    [-1, -2, -1],
    [ 0,  0,  0],
    [ 1,  2,  1]
])

print("Kx:")
print(Kx)

print("Ky:")
print(Ky)


# Convert the grayscale image into a NumPy array
image_array = np.array(G_image)

# Create arrays to store Sobel gradients
Gx = np.zeros((100, 100), dtype=np.float32)
Gy = np.zeros((100, 100), dtype=np.float32)

# Apply Sobel convolution
for y in range(1, 99):
    for x in range(1, 99):

        # Get the 3x3 window
        window = image_array[y-1:y+2, x-1:x+2]

        # Calculate horizontal and vertical gradients
        Gx[y, x] = np.sum(window * Kx)
        Gy[y, x] = np.sum(window * Ky)

print("Sobel convolution completed!")

print("Gx at (1,1):", Gx[1,1])
print("Gy at (1,1):", Gy[1,1])


# Calculate Euclidean edge magnitude
magnitude = np.sqrt(Gx**2 + Gy**2)

print("Euclidean magnitude calculated!")

print("Magnitude at (1,1):", magnitude[1,1])

# Convert magnitude values to 8-bit pixel values
edges_image = np.clip(magnitude, 0, 255).astype(np.uint8)

# Save the Sobel edge image
Image.fromarray(edges_image).save("../edges_python.png")

print("edges_python.png created successfully!")

# Save raw Euclidean magnitude values to python_ref.txt
np.savetxt("../python_ref.txt", magnitude, fmt="%.6f")

print("python_ref.txt created successfully!")