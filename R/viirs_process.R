# processing the viirs data
# making plots for the NOAA Demo
library(raster)
library(rgdal)

# load data
viirs <- raster('geotiffs/viirs_ndvi_raw.tif')

# processing: punch out waterbodies, match resolutions/extent ----------------
# load water polygons & match projections
water <- readOGR('data/hydrology', 'NHDWaterbody')
water <- spTransform(water, projection(viirs))

# match extent and punch out pixels in water bodies
viirs <- mask(viirs, water, inverse = TRUE)

# save output as geotiff (overwrites original)
writeRaster(viirs, 'geotiffs/viirs_ndvi.tif',
            format = 'GTiff', overwrite = TRUE)
