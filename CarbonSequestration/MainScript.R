#ecosystem services script for NatCapCH Tool
#updated: 2021-12-23
#ETH Zürich
#Future Cities Lab Global www.fcl.ethz.ch
#contact: Jens Fischer jefische@ethz.ch

#-----------------------------------------#
#updated: 2022-04-29 
#contact: Laura Schalbetter schalaur@ethz.ch
#-----------------------------------------#

###-----------------------------------------###
#   Ecosystem service: CARBON SEQUESTRATION   #
###-----------------------------------------###

# carbon sequestration and stocks

# this script produces four map layers
# carbon STORAGE in the biomass and soil up to 50 cm down
# carbon SEQUESTRATION in the biomass ONLY
# Swiss ETS
# average Global Social cost of Carbon (SCC)
# so they are not comparable


# load packages
noquote("trigger:progress:0")

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
cstorestandPath <- file.path(args[1],"cseqstand")

# outputs
carbonSequestration_output_name <- "carbon-sequestration.tif"
carbonSequestrationSwissets_output_name <- "carbon-sequestration-swissets.tif"
carbonSequestrationCSS_output_name <- "carbon-sequestration-CSS.tif"
valueswissets_output_name <- "valueswissets.txt"
valuescc_output_name <- "valuescc.txt"

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
#lcm <- raster("exportnew/lcm_zh_1m_forest.tif") #test locally 

#aggregate land cover map from 1m cell size to 10m cell size
lcm10 <- aggregate(lcm, fact=10)

# general lookup table
#lookup <- read.csv(paste(corefolder,"/general lookup table.csv", sep =""))
lookup <- read.csv(lookupTablePath)

#lookup <- read.csv("exportnew/general lookup table.csv") #test locally 

noquote("trigger:progress:20")
# FOR NOW - dont do urban
lookup$carbseq[1:20]<- 0

# import "standard" carbon map 
#cstorestand<- raster(paste(corefolder,"/cseqstand.tif", sep =""))
cstorestand<- raster(cstorestandPath)

#cstorestand <- raster("exportnew/cseqstand.tif") #test locally 

cstorestandraster <- lcm10
cstorestandraster[,]<-0
values(cstorestandraster) <- values(cstorestand) # parks

#---------------------------------------------------------------
#---------------------------------------------------------------


### calculations ###

noquote("trigger:progress:40")
# make a new raster of carbon sequestration (carbseq based on "Carbon modelling overview - Table 1: Values for beenfit transfer for cabon sequestration and stocks)
cseq <- reclassify(lcm10, data.frame(lookup$code.leon10, lookup$carbseq))
# convert from (per ha) to (per 100m2) --> (10x10m = pixelsize)
cseq <- (cseq / 10000) * 100


#sum(getValues(cseq),na.rm= T)

# sg carbon emissions in 2014 were 50.9 million tonnes! 

# make new raster of total carbon - vegetated and 50 cm and leaf litter (mentioned in "How urban Densification influences ecosystem services - a comparison between a temperate & a tropical city")
cstore <- reclassify(lcm10, data.frame(lookup$code.leon10, 
                                       lookup$c.soil50 + lookup$c.veg + lookup$c.litter ))
# convert from (per ha) to (per 100m2)
cstore <- (cstore / 10000) * 100
cstore[is.na(lcm10)] <- NA

#writeRaster(cstore, "exportnew/cseqstand.tif", overwrite=T)

#sum(getValues(cstore),na.rm=T)

#new: (copied from backup_carbon-script): 
# 5 --> Carbon values are assuming a constant 5$ per tonne as per the Singapore carbon tax on industry 
# 3.67 --> One ton of carbon (c) equals 44/12 = 11/3 = 3.67 tons of carbon dioxide /(co2)
#cstoredollar <- cstore*5*3.67

# only look at the differences from standard map 
cstorediff <- cstore - cstorestandraster 

#Swiss ETS: 13.25 (S$ per t Co2 e) <-- NetcapSG Final Report  (*3.67 to get t co2)
cstoreswissets <- round(cstorediff*3.67*13.25)

#average Global Social cost of Carbon (SCC): 74.39  <-- NetcapSG Final Report (*3.67 to get t co2)
cstorescc <- round(cstorediff*3.67*74.39)

noquote("trigger:progress:60")
valueswissets <- cellStats(cstoreswissets, 'sum')
valueswissets <- round(valueswissets)

valuescc <- cellStats(cstorescc, 'sum')
valuescc <- round(valuescc)
#---------------------------------------------------------------
#---------------------------------------------------------------


### output data ###


# save output map
# save it out (cseq or cstore)
# writeRaster(cseq, 
#            paste(savefolder, "/carbon-sequestration.tif", sep=""), overwrite=T)

# writeRaster(cstoreswissets, 
#             paste(savefolder, "/carbon-sequestration-swissets.tif", sep=""), overwrite=T)

# writeRaster(cstorescc, 
#            paste(savefolder, "/carbon-sequestration-CSS.tif", sep=""), overwrite=T)

# write(valueswissets, paste(savefolder, "/valueswissets.txt", sep=""))
# write(valuescc, paste(savefolder, "/valuescc.txt", sep=""))



noquote("trigger:progress:80")

writeRaster(cseq, carbonSequestration_output_name, overwrite=T)
noquote(paste("trigger:output:", carbonSequestration_output_name, sep=""))

writeRaster(cstoreswissets, carbonSequestrationSwissets_output_name, overwrite=T)
noquote(paste("trigger:output:", carbonSequestrationSwissets_output_name, sep=""))

writeRaster(cstorescc, carbonSequestrationCSS_output_name, overwrite=T)
noquote(paste("trigger:output:", carbonSequestrationCSS_output_name, sep=""))

write(valueswissets, valueswissets_output_name)
noquote(paste("trigger:output:", valueswissets_output_name, sep=""))

write(valuescc, valuescc_output_name)
noquote(paste("trigger:output:", valuescc_output_name, sep=""))

noquote("trigger:progress:100")

