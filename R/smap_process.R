# processing the SMAP data
library(raster)
library(rgdal)

# load data
smap <- raster('output/geotiffs/smap_raw.tif')
viirs <- raster('output/geotiffs/viirs_ndvi.tif')

# match resolution (via bilinear interpolation)
smap <- projectRaster(smap, to = viirs)

# match extent and punch out pixels in water bodies
smap <- mask(smap, viirs)

# save output as geotiff (overwrites original)
writeRaster(smap, 'output/geotiffs/smap.tif',
            format = 'GTiff', overwrite = TRUE)
