#ecosystem services script for NatCapCH Tool
#updated: 2021-12-23
#ETH Zürich
#Future Cities Lab Global www.fcl.ethz.ch
#contact: Jens Fischer jefische@ethz.ch

###------------------------------------###
#   Ecosystem service: RUNOFF            #
###------------------------------------###


# load packages
# require(raster)
# require(rgdal)
# require(sp)
# require(gdistance)
# require(rgeos)

noquote("trigger:progress:0")

library(raster, lib="~/R_libs/")
library(rgdal, lib="~/R_libs/")
library(sp, lib="~/R_libs/")
library(igraph, lib="~/R_libs/")
library(gdistance, lib="~/R_libs/")
library(rgeos, lib="~/R_libs/")
rasterOptions(tolerance = 0.4)

# set paths
args <- commandArgs(trailingOnly = TRUE)

#selectedGeotiffPath <- args[2]
selectedGeotiffPath <- file.path(args[1],"input_map")
lookupTablePath <- file.path(args[1],"general_lookup_table")
slopeZhPath <- file.path(args[1],"zh_slope_percent")

# outputs
runoff_10m_output_name <- "runoff.tif"
runoff_10m_output_path <- file.path(args[1], runoff_10m_output_name)
#---------------------------------------------------------------
#---------------------------------------------------------------

### prepare input data ###

# import data needed
# # import general lookup table
#looktbl <- read.csv(paste(corefolder,"/general lookup table.csv", sep =""), head=T)
looktbl <- read.csv(lookupTablePath, head=T)


# # land cover map (based on Bo_Fl vector layers, City of Zurich, Amtliche Vermessung, converted to 1m raster)
lcm <- raster(selectedGeotiffPath) #"lcm_zh_1m.tif"


noquote("trigger:progress:25")
# we don't have data for cn less than 40. convert to this as min for now
looktbl$cn[looktbl$cn < 40] <- 40


# make a new raster of curve numbers
cnras <- lcm
cnras <- reclassify(lcm, data.frame(looktbl$code.leon10, looktbl$cn))

noquote("trigger:progress:50")
# import slope [format: 100%]
#slope_zh <- raster(paste(mapfolder, "/zh_slope_Percent.tif", sep = ""))
slope_zh <- raster(slopeZhPath)

slope_zh <- crop(slope_zh,lcm)
slope_zh[is.na(lcm)] <- NA
# divide by 100 from 100% to 1.0
slope_zh <- slope_zh / 100


# create a new CN to account for slope using formula of Huang et al. 2006
cn_slope <- cnras
cn_slope <- cnras * (322.79 + 15.63 * slope_zh) / (slope_zh + 323.52)
#more than CN 100 is not possible
cn_slope[cn_slope >= 100] <- 100

#---------------------------------------------------------------
#---------------------------------------------------------------

### calculations ###

# estimate runoff for a strong rainfall event in Zurich
# according to "Klimabulletin Juli 2021 there was a maximum of 31mm in 10min
# according to BAFU report on Oberflächenabfluss this maximum in 10min can be considered 36% of an hourly rainfall.
# so 31mm / 36 * 100 = 85mm/h


rainfall_mm <- 85

noquote("trigger:progress:75")
# calculation according to SCS formula for curve number, instead of S = 0.2, we use S = 0.05 which is more accurate for central Europe acc. to Seidel 2008
runoff <- cn_slope
runoff <- (rainfall_mm - 0.05*(2540/cn_slope - 25.4))^2 / ((rainfall_mm - 0.05*(2540/cn_slope - 25.4)) + (2540/cn_slope - 25.4))
runoff_10m <- aggregate(runoff,fact=10)


# convert runoff into % of rainfall for comparability
#runoff_perc <- runoff/rainfall_mm
#runoff_perc_10m <- aggregate(runoff_perc,fact=10)

#---------------------------------------------------------------
#---------------------------------------------------------------

### save output map ###

# save it out
#writeRaster(runoff_10m, paste(savefolder,"/runoff.tif", sep=""), overwrite=T)
#writeRaster(runoff_10m, file.path(args[1],"output_map"), overwrite=T)
#writeRaster(runoff_perc, paste(savefolder, "/runoff_perc.tif", sep=""), overwrite=T)

writeRaster(runoff_10m, runoff_10m_output_path, overwrite=T)
noquote(paste("trigger:output:", runoff_10m_output_name, sep=""))

noquote("trigger:progress:100")
