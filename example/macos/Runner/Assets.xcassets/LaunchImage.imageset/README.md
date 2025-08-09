# Launch Image Instructions

To complete the theme fix, you need to add launch images with a light background:

1. Create a 1024x768 PNG image with background color #F5F5F7 (light gray)
2. Save it as `LaunchImage.png` in this directory
3. Create a 2048x1536 version and save as `LaunchImage@2x.png`

Alternatively, you can create them using this command in Terminal:

```bash
# Create 1x image
convert -size 1024x768 xc:'#F5F5F7' LaunchImage.png

# Create 2x image  
convert -size 2048x1536 xc:'#F5F5F7' LaunchImage@2x.png

# Create 3x image  
convert -size 3072x2304 xc:'#F5F5F7' LaunchImage@3x.png
```

If you don't have ImageMagick installed:
```bash
brew install imagemagick
```
