# Makefile for the noaa demo
PLOTS = output/plots/scatter1.pdf output/plots/scatter2.pdf output/plots/levelplots.pdf output/plots/surfs.pdf
GEOTIFFS = output/geotiffs/viirs_ndvi.tif output/geotiffs/smap.tif
OUTPUT = $(GEOTIFFS) $(PLOTS)

all: $(OUTPUT)

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
	mkdir -p output/geotiffs
	R CMD BATCH --vanilla R/viirs_read.R
	R CMD BATCH --vanilla R/viirs_process.R
	R CMD BATCH --vanilla R/smap_read.R
	R CMD BATCH --vanilla R/smap_process.R
	rm output/geotiffs/*_raw.tif

# make some plots and do some simple analysis
$(PLOTS): $(GEOTIFFS) R/make_plots.R data/ecoregions
	mkdir -p output/plots
	R CMD BATCH --vanilla R/make_plots.R
	rm Rplots.pdf
	rm *.Rout

	# remove any prior output from the s3 bucket
	aws s3 rm s3://curcbucket/noaa-output --recursive

	# export the output back to the s3 bucket
	aws s3 cp output s3://curcbucket/noaa-ouput --recursive
