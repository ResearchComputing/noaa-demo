# Makefile for the noaa demo
PLOTS = plots/scatter1.pdf plots/scatter2.pdf plots/levelplots.pdf plots/surfs.pdf
GEOTIFFS = geotiffs/viirs_ndvi.tif geotiffs/smap.tif

all: $(GEOTIFFS) $(PLOTS)

data:
	mkdir -p data

data/viirs.h5:
	aws s3 cp s3://curcbucket/VIIRS/NEW/GITCO-VIVIO_npp_d20150628_t2035460_e2041264_b19004_c20160426144157736220_noaa_ops.h5 data/viirs.h5

data/smap.h5:
	aws s3 cp s3://curcbucket/SMAP/SMAP_L4_SM_gph_20150628T013000_Vb1010_001.h5 data/smap.h5

data/ecoregions:
	aws s3 cp s3://curcbucket/epa_ecoregions data/ecoregions --recursive

data/hydrology:
	aws s3 cp s3://curcbucket/hydrology_data data/hydrology --recursive

# convert the hdf5 files to geotiffs with matched projections and save
$(GEOTIFFS): data/viirs.h5 R/viirs_read.R R/viirs_process.R data/hydrology data/smap.h5 R/smap_read.R R/smap_process.R
	mkdir -p geotiffs
	R CMD BATCH --vanilla R/viirs_read.R
	R CMD BATCH --vanilla R/viirs_process.R
	R CMD BATCH --vanilla R/smap_read.R
	R CMD BATCH --vanilla R/smap_process.R
	rm geotiffs/*_raw.tif

# make some plots and do some simple analysis
$(PLOTS): $(GEOTIFFS) R/make_plots.R data/ecoregions
	mkdir -p plots
	R CMD BATCH --vanilla R/make_plots.R
	rm Rplots.pdf
	rm *.Rout
