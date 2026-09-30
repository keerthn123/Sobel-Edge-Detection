import numpy as np

# Read Python reference results
python_ref = np.loadtxt("python_ref.txt")

# Read VHDL results
vhdl_ref = np.loadtxt("SobelEdgeVHDL.txt")

# Python gives a 100x100 image
python_image = python_ref.reshape(100, 100)

# VHDL gives only the valid 98x98 pixels
vhdl_image = vhdl_ref.reshape(98, 98)

# Take the same 98x98 interior from the Python result
python_interior = python_image[1:99, 1:99]

# Calculate absolute difference
difference = np.abs(python_interior - vhdl_image)

# Calculate total error
total_error = np.sum(difference)

# MAE over the 100x100 image as required by the project
mae = total_error / 10000

print("====================================")
print("   PYTHON vs VHDL SOBEL COMPARISON")
print("====================================")

print("Python image size:", python_image.shape)
print("VHDL image size:", vhdl_image.shape)

print("Total Error:", total_error)
print("MAE:", mae)

print("Maximum Difference:", np.max(difference))
print("Average Difference on valid 98x98 pixels:",
      np.mean(difference))

print("====================================")
print("Comparison completed successfully!")
print("====================================")


import matplotlib.pyplot as plt

# Display the difference matrix as a heatmap
plt.figure(figsize=(8, 6))
plt.imshow(difference, cmap="hot")
plt.colorbar(label="Absolute Difference")
plt.title("Python vs VHDL Sobel Difference Heatmap")
plt.xlabel("Pixel X")
plt.ylabel("Pixel Y")

# Save the heatmap
plt.savefig("difference_heatmap.png", dpi=300, bbox_inches="tight")

plt.show()

print("Difference heatmap created successfully!")


from PIL import Image

# Create a 100x100 image for the VHDL result
vhdl_full = np.zeros((100, 100), dtype=np.float32)

# Put the 98x98 VHDL result in the valid interior
vhdl_full[1:99, 1:99] = vhdl_image

# Convert values to displayable 8-bit pixels
vhdl_display = np.clip(vhdl_full, 0, 255).astype(np.uint8)

# Save VHDL edge image
Image.fromarray(vhdl_display).save("vhdl_edges.png")

print("VHDL edge image created successfully!")


