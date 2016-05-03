viirs_read <- function(input_file,
                          group = 'All_Data/VIIRS-VI-EDR_All',
                          dataset = 'TOA_NDVI',
                          crs_in = '+proj=longlat +lat_0=0 +lon_0=0 +ellps=WGS84 +datum=WGS84',
                          crs_out = "+init=epsg:4326",
                          min_lon = -180, max_lon = 180,
                          min_lat = -180, max_lat = 180,
                          keep = 10000) {
  require(rhdf5)
  require(data.table)
  require(raster)
  require(akima)
  input <- h5read(input_file,
                  paste0('/', group, '/', dataset))
  lat <- h5read(input_file, '/All_Data/VIIRS-IMG-GEO-TC_All/Latitude')
  lon <- h5read(input_file, '/All_Data/VIIRS-IMG-GEO-TC_All/Longitude')

  # assemble into a multi-column data frame (actually data table)
  df <- data.table(lat = c(lat),
                   lon = c(lon),
                   ndvi = c(input))

  # subset the data to the area of interest, excluding crazy ndvi values
  df <- subset(df, ndvi < 6.1E4 & lon > min_lon &
                 lon < max_lon & lat > min_lat & lat < max_lat)
  df <- df[sample(nrow(df), keep), ]

  # define coordinates and projection
  coordinates(df) <- c('lon', 'lat')
  projection(df) <- '+proj=longlat +lat_0=0 +lon_0=0 +ellps=WGS84 +datum=WGS84'

  # use bilinear interpolation to get the data on a grid
  surf <- interp(df, z = 'ndvi', nx = 50, ny = 40)

  # project the NDVI surface
  pr_surf <- spTransform(surf, crs_out)
  gridded(pr_surf) <- TRUE
  pr_surf <- raster(x = pr_surf, layer = 1, values = TRUE)
  return(pr_surf)
}


viirs <- viirs_read(input_file = 'data/viirs.h5',
                    min_lon = -109.05, max_lon = -102.05,
                    min_lat = 37, max_lat = 41,
                    crs_out = "+init=epsg:4326",
                    keep = 50000)

writeRaster(viirs, 'geotiffs/viirs_ndvi_raw.tif',
            format = 'GTiff', overwrite = TRUE)
