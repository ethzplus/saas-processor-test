#ecosystem services script for NatCapCH Tool
#updated: 2021-12-23
#ETH Zürich
#Future Cities Lab Global www.fcl.ethz.ch
#contact: Jens Fischer jefische@ethz.ch

###-----------------------------------------###
#   Ecosystem service: CARBON SEQUESTRATION   #
###-----------------------------------------###

# carbon sequestration and stocks

# this script produces two map layers
# carbon STORAGE in the biomass and soil up to 50 cm down
# carbon SEQUESTRATION in the biomass ONLY
# so they are not comparable


# load packages
library(raster, lib="~/R_libs/")
library(rgdal, lib="~/R_libs/")
library(sp, lib="~/R_libs/")
library(igraph, lib="~/R_libs/")
library(gdistance, lib="~/R_libs/")
library(rgeos, lib="~/R_libs/")

# set paths
args <- commandArgs(trailingOnly = TRUE)

selectedGeotiffPath <- file.path(args[1],"input_map")
lookupTablePath <- file.path(args[1],"general_lookup_table")

# outputs
carbonStorage_output_name <- "carbon-storage.tif"


# sharedPath <- args[1]
# print(sharedPath)

# selectedGeotiffPath <- args[2]
# print(selectedGeotiffPath)

# savefolder <- args[3]
# print(savefolder)


# corefolder <- sharedPath
# mapfolder <- sharedPath

#---------------------------------------------------------------
#---------------------------------------------------------------


### prepare input data ###


# import data needed
# # land cover map (based on Bo_Fl vector layers, City of Zurich, Amtliche Vermessung, converted to 1m raster)
lcm <- raster(selectedGeotiffPath) #"lcm_zh_1m.tif"

#aggregate land cover map from 1m cell size to 10m cell size
lcm10 <- aggregate(lcm,fact=10)

# general lookup table
#lookup <- read.csv(paste(corefolder,"/general lookup table.csv", sep =""))
lookup <- read.csv(lookupTablePath)



# FOR NOW - dont do urban
lookup$carbseq[1:20]<- 0

noquote("trigger:progress:50")
#---------------------------------------------------------------
#---------------------------------------------------------------


### calculations ###


# make a new raster of carbon sequestration
cseq <- reclassify(lcm10, data.frame(lookup$code.leon10, lookup$carbseq))
# convert from (per ha) to (per 100m2)
cseq <- (cseq / 10000) * 100


#sum(getValues(cseq),na.rm= T)

# sg carbon emissions in 2014 were 50.9 million tonnes! 

# make new raster oftotal carbon - vegetated and 50 cm and leaf litter
cstore <- reclassify(lcm10, data.frame(lookup$code.leon10, 
                                       lookup$c.soil50 + lookup$c.veg + lookup$c.litter ))
# convert from (per ha) to (per 100m2)
cstore <- (cstore / 10000) * 100

#sum(getValues(cstore),na.rm=T)


#---------------------------------------------------------------
#---------------------------------------------------------------


### output data ###


# save output map
# save it out
#writeRaster(cseq, 
#           paste(savefolder, "/carbon-sequestration.tif", sep=""), overwrite=T)
#writeRaster(cstore, 
#            paste(savefolder, "/carbon-storage.tif", sep=""), overwrite=T)

writeRaster(cseq, carbonStorage_output_name, overwrite=T)
noquote(paste("trigger:output:", carbonStorage_output_name, sep=""))

noquote("trigger:progress:100")