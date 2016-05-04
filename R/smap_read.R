# script to create raster object from smap data in hdf5 format
smap_read <- function(input_file,
                         group,
                         dataset,
                         missing_vals = -9999,
                         crs_in = '+proj=cea +lat_0=0 +lon_0=0 +lat_ts=30 +ellps=WGS84 +datum=WGS84 +units=m',
                         crs_out = "+init=epsg:4326") {
  require(rhdf5)
  require(raster)
  input <- h5read(input_file, paste0('/', group, '/', dataset))
  input[input == missing_vals] <- NA
  r <- raster(t(input))
  lat <- apply(h5read(input_file, '/cell_lat'), 2, unique)
  lon <- apply(h5read(input_file, '/cell_lon'), 2, unique)
  ex <- extent(projectExtent(raster(extent(range(lon), range(lat)),
                                    crs = "+proj=longlat +lat_0=0 +lon_0=0 +lat_ts=30 +ellps=WGS84 +datum=WGS84 +units=m"),
                             crs_in))
  extent(r) <- ex
  projection(r) <- CRS(crs_in)
  output <- projectRaster(r, crs = crs_out)
  return(output)
}

smap <- smap_read(input_file = 'data/smap.h5',
                     group = 'Geophysical_Data',
                     dataset = 'sm_rootzone',
                     crs_out = "+init=epsg:4326")

writeRaster(smap, 'output/geotiffs/smap_raw.tif',
            format = 'GTiff', overwrite = TRUE)
