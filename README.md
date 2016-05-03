# NOAA data partnership demo

The goal here is to relate soil moisture data (SMAP data from NSIDC & NASA) to NDVI (from VIIRS).
The R implementation is contained in the `R` directory.
The Makefile is the master script for running the analysis in R, which loads the data from the `curcbucket` S3 bucket, processes it, and saves some output in `plots/`.
To access the S3 bucket, ensure that the Amazon Web Services Command Line Interface is installed and configured (via `aws configure` as described [here](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)).

This project is designed to be run inside of a container with a custom R/Ubuntu environment called `earthlab-r`, which is available on [Docker Hub](https://hub.docker.com/r/mbjoseph/earthlab-r/).
