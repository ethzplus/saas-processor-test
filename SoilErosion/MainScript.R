#ecosystem services script for NatCapCH Tool
#updated: 2021-12-23
#ETH Zürich
#Future Cities Lab Global www.fcl.ethz.ch
#contact: Jens Fischer jefische@ethz.ch

###---------------------------------###
#   Ecosystem service: SOIL EROSION   #
###---------------------------------###

# load packages
library(raster, lib="~/R_libs/")
library(rgdal, lib="~/R_libs/")
library(sp, lib="~/R_libs/")
library(igraph, lib="~/R_libs/")
library(gdistance, lib="~/R_libs/")
library(rgeos, lib="~/R_libs/")
rasterOptions(tolerance = 0.4)

# set paths
args <- commandArgs(trailingOnly = TRUE)

selectedGeotiffPath <- file.path(args[1],"input_map")
dhm_zh_10mPath <- file.path(args[1],"dhm_zh_10m") 
lookupTablePath <- file.path(args[1],"general_lookup_table")
flowacc_zh_10mPath <- file.path(args[1],"flowacc_zh_10m") 
slope_deg_zh_10mPath <- file.path(args[1],"slope_deg_zh_10m") 
ndvi_zh_10mPath <- file.path(args[1],"ndvi_zh_10m") 

# outputs
soilLoss_output_name <- "soil_loss.tif"


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


# # dem

# dem <- raster(paste(mapfolder,"/dhm_zh_10m.tif", sep =""))
dem <- raster(dhm_zh_10mPath)

noquote("trigger:progress:20")
# # import general lookup table
# looktbl <- read.csv(paste(corefolder,"/general lookup table.csv", sep =""), head=T)
looktbl <- read.csv(lookupTablePath, head=T)

# create reference map for soil categories
gaw2019 <- reclassify(lcm10, data.frame(looktbl$code.leon10, looktbl$gaw.2019.code))


# # import flow accumulation map
#acc <- raster(paste(mapfolder, "/flowacc_zh_10m.tif", sep = ""))
acc <- raster(flowacc_zh_10mPath)

# # import slope map [format: degrees]
# zh_slope <- raster(paste(mapfolder, "/slope_deg_zh_10m.tif", sep = ""))
zh_slope <- raster(slope_deg_zh_10mPath)

# # import ndvi map
# ndvi <- raster(paste(mapfolder,"/ndvi_zh_10m.tif", sep =""))
ndvi <- raster(ndvi_zh_10mPath)


noquote("trigger:progress:40")
#---------------------------------------------------------------
#---------------------------------------------------------------

# rainfall erosivity = R
# will be taken from Panagos et al 2017 when data come in.
# around 7400 for now
#globalR <- raster(paste(mapfolder,"rainfall-erosivity.tif", sep =""))
globalR <- lcm10
globalR[!is.na(lcm10)] <- 526 #this is a number for most of central Europe (Panagos et al. 2017:4)
# R is in MJ mm ha per year

# soil erodibility = K
# Wischmeier W, Smith D. 1978.Predicting rainfall erosion losses.
#A guide to conservation planning. Washington DC: Science
#and Education Administration, U.S. Department of Agriculture.
# this one is annoying and needs some constants we don't have
# instead use Torri et al 1997
# empirical only - organic matter and ssc onctent
# import K from the spreadsheet, this bit was just for the maths


# make raster
K <- reclassify(lcm10, data.frame(looktbl$code.leon10, looktbl$k.soil.erodibility))
#K <- reclassify(leon10, as.matrix(looktbl[,c(2,15)]))
#K[!is.na(K)]<-0.1102

# topographic factors LS
# LS = ((a * p)/22.13)^m * (sin(d)/0.896)^1.3
# a = flow accumulation  ### a = acc
# p = pixel size of dem  ### p = 1m
# d = slope model in degrees  ### d = zh_slope
#LS<- raster(paste(mapfolder,"topographic-factor-2020.tif", sep =""))

LS <- ((acc * 1)/22.13)^0.4 * (sin(zh_slope)/0.896)^1.3  # Moore 1986
noquote("trigger:progress:60")

# C is the amount of vegetation cover = proportion with bare soil
# could do this either by NDVI --> exp(-2 *(NDVI/(1-NDVI)))
# calculate C as the exp(-2 *(NDVI/(1-NDVI))) as per Knijff et al 2000

C <- exp(-2 *(ndvi/(1-ndvi)))
C[gaw2019 ==1 ] <- NA # exclude buildings
C[gaw2019 ==2 ] <- NA # exclude sealed surfaces
#C[leon10 ==1 ] <- NA
#C[leon10 ==2 ] <- NA


# guerra et al 2014 ES estimation
# units are tons per ha
# SI (structural impact) is R * LS * K (Guerra et al 2014)
#SI <- globalR * LS$topographic.factor.2020 * K
SI <- globalR * LS * K
#SI[leon10 ==1 ] <- NA
#SI[leon10 ==2 ] <- NA
SI[gaw2019 ==1 ] <- NA # exclude buildings
SI[gaw2019 ==2 ] <- NA # exclude sealed surfaces



# calculate A = absolute soil erosion
A <- globalR * LS * K *C
#A[leon10 ==1 ] <- NA
#A[leon10 ==2 ] <- NA
A[gaw2019 ==1 ] <- NA # exclude buildings
A[gaw2019 ==2 ] <- NA # exclude sealed surfaces
quantile(A, c(0.05, 0.10, 0.5, 0.75,0.95,0.99))
mean(getValues(A),na.rm=T)
# reasonable - high. median of 24 tons ha year. 95% of 198.7
# 180 000 tonnes or about 160714 metric tons is about 1m depth of 1 ha
# so even loss of 4000 tons ha per year is only
#1/(180000/ 4000) # so 4000 tons is 2 cm of the whole ha - totally possible
#1/(180000/ 400) # and the 99 percentile of 400 is 2 mm

# Labiere review bare ground is about 1500 g m2 per year.
#(1500 * 10000) * 1e-6 # equivalent in tonnes per ha
# grass is
#(35 * 10000) * 1e-6 # equivalent in tonnes per ha
# forest is
#(10 * 10000) * 1e-6 # equivalent in tonnes per ha

# Labiere review tree/ forest  is about 10/30 g m2 per year.
#(c(10,30) * 10000) * 1e-6 # equivalent in tonnes per ha

# calculate ES as SI- fraction of eroded soil after considering C
ES <- SI-A


# remove 0 values - no soil loss on concrete
#SI[leon10 == 3] <- NA
#ES[leon10 == 3] <- NA
#A[leon10 == 3] <- NA
noquote("trigger:progress:800")
# remove buildings
SI[gaw2019 == 1] <- NA
ES[gaw2019 == 1] <- NA
A[gaw2019 == 1] <- NA

# remove sealed surfaces
SI[gaw2019 == 2] <- NA
ES[gaw2019 == 2] <- NA
A[gaw2019 == 2] <- NA

# remove water values too
#SI[leon10 == 1] <- NA
#ES[leon10 == 1] <- NA
#A[leon10 == 1] <- NA

#SI[leon10 == 2] <- NA
#ES[leon10 == 2] <- NA
#A[leon10 == 2] <- NA

# remove water courses
SI[gaw2019 == 11] <- NA
ES[gaw2019 == 11] <- NA
A[gaw2019 == 11] <- NA

# remove water bodies
SI[gaw2019 == 12] <- NA
ES[gaw2019 == 12] <- NA
A[gaw2019 == 12] <- NA

# remove marine
SI[gaw2019 == 13] <- NA
ES[gaw2019 == 13] <- NA
A[gaw2019 == 13] <- NA


# convert to 99 percentile max
A[A>quantile(A,c(0.99))]<-quantile(A,c(0.99))
ES[ES>quantile(ES,c(0.99))]<-quantile(ES,c(0.99))
SI[SI>quantile(SI,c(0.99))]<-quantile(SI,c(0.99))

#plot(ES) # ecosystem service in tons per ha
#plot(A) # absolute reaslised soil loss in tons per hap
#plot(ES/SI) # percentage of potential soil loss being prevented by vegetation

# convert to per pixel values to make sensible
# only relevant if quantifying something within a boundary
# e.g. absolute soil loss or absolute soil protection
sum(getValues(ES)/(10*9.93), na.rm=T)
sum(getValues(A)/(10*9.93), na.rm=T)
# so 2.1 million tons of soil lost per year
# and 5.9 million tons protected by vegetation each year


#---------------------------------------------------------------
#---------------------------------------------------------------

# write out the outputs
#writeRaster(A,
#            paste(savefolder, "/soil-loss-HA.tif", sep=""), overwrite=T)
#writeRaster(ES,
#            paste(savefolder, "/soil-protection-veg-HA.tif", sep=""), overwrite=T)
#writeRaster(ES/SI,
#            paste(savefolder, "/soil-protection-veg-percent-HA.tif", sep=""), overwrite=T)


# convert to actual tonnes rather than tonnes per ha
# area of a cell in m is res(eastcoast)[1] * res(eastcoast)[2] assuming map units are m
ES <- ES * ((res(ES)[1] * res(ES)[2])/10000)
SI <- SI * ((res(ES)[1] * res(ES)[2])/10000)
A <- A * ((res(ES)[1] * res(ES)[2])/10000)


# write out the outputs
#writeRaster(A,
#            paste(savefolder, "/soil-loss.tif", sep=""), overwrite=T)
#writeRaster(ES,
#            paste(savefolder, "/soil-loss.tif", sep=""), overwrite=T)
#writeRaster(ES/SI,
#            paste(savefolder, "/soil-protection-veg-percent.tif", sep=""), overwrite=T)
writeRaster(ES, soilLoss_output_name, overwrite=T)
noquote(paste("trigger:output:", soilLoss_output_name, sep=""))

noquote("trigger:progress:100")

