# making plots for the NOAA Demo
library(raster)
library(rgdal)
library(dplyr)
library(ggplot2)
library(plot3D)
library(gridExtra)
library(rasterVis)
library(colorspace)

# load data
smap <- raster('geotiffs/smap.tif')
viirs <- raster('geotiffs/viirs_ndvi.tif')

# do projections match?
stopifnot(projection(smap) == projection(viirs))

# bundle up the data into a stack
s <- stack(scale(smap), scale(viirs))

# match ecoregions to the smap and ndvi data
ecoregion <- readOGR('data/ecoregions', 'co_eco_l4')
ecoregion <- spTransform(ecoregion, projection(smap))
r_region <- rasterize(ecoregion, smap)

smap_df <- as(smap, 'SpatialPointsDataFrame')
eco_points <- over(smap_df, ecoregion)
eco_points <- cbind(eco_points, as.data.frame(smap_df)['smap'])
eco_points <- cbind(eco_points,
                    as.data.frame(as(viirs, 'SpatialPointsDataFrame')))

# determine which ecoregions are common (in terms of area)
eco_freq <- eco_points %>%
  group_by(US_L4NAME) %>%
  summarize(freq = n()) %>%
  arrange(freq) %>%
  mutate(common = freq > median(freq))
eco_points <- full_join(eco_points, eco_freq)

# visualize results ---------------------------------------------------
s1 <- ggplot(eco_points, aes(x = smap, y = viirs_ndvi - min(viirs_ndvi))) +
  geom_point(alpha = 1) +
  scale_y_log10() +
  xlab('Soil moisture') +
  ylab('Plant greenness') +
  theme_minimal()
ggsave('plots/scatter1.pdf', plot = s1, width = 6, height = 4)

s2 <- eco_points %>%
  filter(common) %>%
  ggplot(aes(x = smap, y = viirs_ndvi - min(viirs_ndvi),
             color = US_L4NAME)) +
  geom_point(alpha = .5) +
  scale_y_log10() +
  facet_wrap(~US_L4NAME) +
  xlab('Soil moisture') +
  ylab('Plant greenness') +
  theme_minimal() +
  stat_smooth(method = 'lm', formula = y ~ poly(x, 2),
              se = FALSE) +
  theme(legend.position = 'none')
ggsave('plots/scatter2.pdf', plot = s2, width = 12, height = 8)


myTheme <- rasterTheme(region = rev(diverge_hcl(20, c = 100, l = c(50, 90),
                                                power = 1)))
l1 <- levelplot(s, par.settings = myTheme,
                margin = list(FUN = median), layers = 1,
                main = 'Soil moisture')

l2 <- levelplot(s,
                par.settings = rasterTheme(region = brewer.pal('Greens', n = 9)),
                margin = list(FUN = median), layers = 2,
                main = 'Vegetation greenness (NDVI)')
g <- arrangeGrob(l1, l2, nrow = 1)
ggsave(file = "plots/levelplots.pdf", plot = g, width = 12, height = 8, units = 'in')

pdf(file = 'plots/surfs.pdf', width = 8, height = 6)
par(mfrow = c(2, 1), mar = c(0, 0, 1, 0))
persp3D(z = as.matrix(smap),
        theta = 0, phi = 45, r = 1,
        colkey = FALSE,
        box = FALSE, border = alpha(1, .03),
        expand = .3,
        colvar = as.matrix(smap),
        col = brewer.pal(9, "Greens"))
title('Vegetation greenness (NDVI)')
persp3D(z = as.matrix(viirs),
        theta = 0, phi = 45, r = 1,
        colkey = FALSE,
        box = FALSE, border = alpha(1, .03),
        expand = .3,
        colvar = as.matrix(viirs),
        col = brewer.pal(9, "Blues"))
title('Soil moisture')
dev.off()
par(mar = c(5, 4, 4, 2) + 0.1, mfrow = c(1, 1))
