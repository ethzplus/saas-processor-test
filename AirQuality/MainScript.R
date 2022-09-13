#ecosystem services script for NatCapCH Tool
#updated: 2021-12-23
#ETH Zürich
#Future Cities Lab Global www.fcl.ethz.ch
#contact: Jens Fischer jefische@ethz.ch

###---------------------------------------###
#   Ecosystem service: AIR QUALITY - PM10   #
###---------------------------------------###

# load packages
noquote("trigger:progress:0")

library(raster, lib="~/R_libs/")
library(rgdal, lib="~/R_libs/")
library(sp, lib="~/R_libs/")
library(igraph, lib="~/R_libs/")
library(gdistance, lib="~/R_libs/")
library(rgeos, lib="~/R_libs/")
#rasterOptions(tolerance = 0.4)

# set paths
args <- commandArgs(trailingOnly = TRUE)

selectedGeotiffPath <- file.path(args[1],"input_map")
laiPath <- file.path(args[1],"lai_zh_10m")
vegheightPath <- file.path(args[1],"vegheight_zh_10m")
meirPath <- file.path(args[1], "meir_et_al_2000_vertical")
outputPath <- file.path(args[1],"output_map")
#---------------------------------------------------------------
#---------------------------------------------------------------


### prepare input data ###


# import data needed

# # land cover map (based on Bo_Fl vector layers, City of Zurich, Amtliche Vermessung, converted to 1m raster)
lcm <- raster(selectedGeotiffPath) #"lcm_zh_1m.tif"

#aggregate land cover map from 1m cell size to 10m cell size
lcm10 <- aggregate(lcm,fact=10)

# # lai map
lai <- raster(laiPath)

# # vegetation height map
vegheight <- raster(vegheightPath)



# relationship for below-canopy forest lai
meir <- read.csv(meirPath)
# check not more than 1 or less than 0
meir$height[meir$height > 1] <- 1
meir$height[meir$height < 0] <- 0

# convert raw canopyint to cumulative
cumsum2 <- function(x){
  cumsum(x)/ sum(x)
}

meir$leafdensity
meir$cumleafd <- 0
meir[meir$site == levels(meir$site)[1],]$cumleafd <-
  cumsum2(meir[meir$site == levels(meir$site)[1],]$leafdensity)
meir[meir$site == levels(meir$site)[2],]$cumleafd <-
  cumsum2(meir[meir$site == levels(meir$site)[2],]$leafdensity)
meir[meir$site == levels(meir$site)[3],]$cumleafd <-
  cumsum2(meir[meir$site == levels(meir$site)[3],]$leafdensity)
meir[meir$site == levels(meir$site)[4],]$cumleafd <-
  cumsum2(meir[meir$site == levels(meir$site)[4],]$leafdensity)
#
meir$cumleafd2 <- (1-meir$cumleafd)

#tiff(filename = "~/Documents/Projects/Interception LAI/manuscript/Figure2.tif",
#    width = 85, height = 100, units = "mm", pointsize = 12,
#   bg = "white", res = 600)
par(mar=c(5.1,4.1,1.1,1.1))
gf <- meir$site
levels(gf) <-c("green4", "black","blue","red")
gf <- as.character(gf)
#plot(cumleafd2 ~ height, col = gf, data = meir, pch = 16,
#     xlab = "Proportion canopy height", ylab = "Cumulative leaf area density")

# cannot model as quasibinomial, try normal
# m2 <- lmer(cumleafd2 ~ height + (1|site),  data =meir)
# summary(m2)

#m3 <- lmer(sqrt(cumleafd2) ~ height + (1|site),  data =meir)
#summary(m3)

#abline(-0.0138,0.9555) # m2

#legend("topleft",
#       levels(meir$site),
#       pch = 16,
#       col=c("green4", "black","blue","red"), cex=0.8, bty = "n")

#dev.off()
noquote("trigger:progress:25")
# if there is no vegheight data from angela, assume 30 m
vegheight[is.na(vegheight)] <- 30
# also assume a max tree height of 60m - cut off anything taller than that
vegheight[vegheight > 60] <- 60


# ok so fill vegheight with the right data
underint <- vegheight
underint[,]<- 0

# extract the data for forest only and convert
# get veg height
underint[lcm10 == 35] <- vegheight[lcm10==35]
underint[lcm10 == 38] <- vegheight[lcm10==38]
# convert to the proportion that 2.5 is
underint <- 2.5/underint
underint[underint > 1] <- 0
# so now we know how much % is understorey, can calculate the total
underint <- ((underint*0.9555)+-0.0138) # this is the proportion of the leaf density/ therefore by inference also the proportion of LAI
# logic checks
underint[underint < 0] <- 0
underint[underint >1] <- 1
# make it artificially so that cannot be more than 50% of lai - we have some errors in the hieght dataset
underint[underint >0.5] <- 0.5
#this gets the 100% lai and then multiply by underint to get the underint lai
underint <- (lai/ (1-underint))*underint
# remove non-forest again
underint[lcm10 != 35 & lcm10 != 38] <- 0

# ok clean up lai so that it does not include urban or water
lai[is.na(lcm10)]<-NA
lai[lcm10 == 1|lcm10 == 2|lcm10 == 3|lcm10 == 4|lcm10 == 5|lcm10 == 6|lcm10 == 7|lcm10 == 8|lcm10 == 9|lcm10 == 10|
      lcm10 == 1|lcm10 == 1|lcm10 == 1|lcm10 == 1|lcm10 == 1|lcm10 == 1|lcm10 == 1|lcm10 == 1|lcm10 == 1|
      lcm10 == 11|lcm10 == 12|lcm10 == 13|lcm10 == 14|lcm10 == 15|lcm10 == 16|lcm10 == 17|lcm10 == 18|lcm10 == 19|lcm10 == 20]<- 0
lai[lcm10 == 32]<- 0
lai[lcm10 == 33]<- 0
lai[lcm10 == 40]<- 0

# for grass, make it 2 minimum
#lai[lcm10 == 22 & lai < 2] <- 2
#lai[lcm10 == 23 & lai < 2] <- 2
#lai[lcm10 == 24 & lai < 2] <- 2
#lai[lcm10 == 25 & lai < 2] <- 2
#lai[lcm10 == 26 & lai < 2] <- 2
#lai[lcm10 == 27 & lai < 2] <- 2

lai <- projectRaster(lai,lcm10)

lai[lcm10 == 22 & lai < 2] <- 2
lai[lcm10 == 23 & lai < 2] <- 2
lai[lcm10 == 24 & lai < 2] <- 2
lai[lcm10 == 25 & lai < 2] <- 2
lai[lcm10 == 26 & lai < 2] <- 2
lai[lcm10 == 27 & lai < 2] <- 2



# add the canopy < 2m lai
lai <- lai + underint


#---------------------------------------------------------------
#---------------------------------------------------------------


### calculations ###

# use the equation Q = F*L*T*0.5 from Manes et al .2016
# where F = V*C
#C=concentration in air
#V = dry deposition velocity
#L = LAI
#T = period of time
# Lovett et al. 1994 suggest 0.0064m/s
# but zhongyu et al 2019 20 spp from Singapore median  = 0.9671

# take numbers from NEA dataset pm10_2nd_maximum_24hourly_mean
# microgram per m3
# 75 in 2014
# 215 in 2013
# urbancok et al 2017 a low day would be 32-70. Haze day 72 -310+

qDAY75 <-  ((0.0064/6) * 84* 1e-6 ) * (lai  * 10 * 9.93) *   (24*60 * 60) * 0.5
# units are now in grams already 

# fit strongly to boundary
qDAY75  <- mask(qDAY75, lcm10)
#qDAY32  <- mask(qDAY32, leon10)
noquote("trigger:progress:50")
qDAY75[qDAY75  < 0]<-0

# convert to gram
#q1<- q1*1e-6
sum(getValues(qDAY75 ),na.rm=T) # national total in gram
sum(getValues(qDAY75 ),na.rm=T) * 1e-6# national total in tonnes

(mean(getValues(qDAY75 ),na.rm=T)   )/ 99.3# average in g per m2 per day
(range(getValues(qDAY75 ),na.rm=T)   )/ 99.3# average in g per m2
# nowak et al report 7.4 gm2 annually given an ambient conc of about 78 microgram m3
7.4/ 365 # quite similar for trees = 0.02
# Botalico et al give 0.01 - 0.02 tons per ha per year for forests
(0.02 * 0.0001 ) /1e-6/ 365 # = 0.005 g ha day

# tg <- cbind(getValues(qDAY75 )/99.3,
# getValues(leon10 ))
# cbind(tapply(tg[,1], tg[,2], mean, na.rm=T),
# tapply(tg[,1], tg[,2], min, na.rm=T),
# tapply(tg[,1], tg[,2], max, na.rm=T),
# tapply(tg[,2], tg[,2], mean, na.rm=T)
# )
noquote("trigger:progress:75")
# calculate removal from air
# based on tallis etal 2011 model
# based on Li et al 2013 Singapore PBL/ Mixing height model.
# a night average would be 100 m
# a day average would be 700 m
# a rough average would be 400 m

# mean annual pm10 conc * mean annaul mixing layer height *
# 8760 (hours per year) * land area covered by urban canopy

# this one will do the annual removal. But first we need mean annual conc
#totalPM10 <- 84 * 100 * 8760 * (sum(!is.na(getValues(qDAY75 )))*10*9.93)
totalPM10_DAY75 <- 84 * 1e-6 * 557 *  (sum(!is.na(getValues(lcm10 )))*10*9.93)
#totalPM10_DAY32 <- 32 * 100 * 24*60*60 * (sum(!is.na(getValues(qDAY32 )))*10*9.93)

# percentage reduction in concentration
((sum(getValues(qDAY75),na.rm=T)) / totalPM10_DAY75 )*100
#((sum(getValues(qDAY32),na.rm=T)) / totalPM10_DAY32 )*100


# convert to grams 
#grams <- qDAY75
# convert to grams per m2
#gm2<- qDAY75 /99.3

#---------------------------------------------------------------
#---------------------------------------------------------------

# save output map
# save it out
writeRaster(qDAY75, outputPath, overwrite=T)
#writeRaster(grams,
#            paste(savefolder, "/pm10-grams.tif", sep=""), overwrite=T)
#writeRaster(gm2,
#            paste(savefolder, "/pm10-gm2.tif", sep=""), overwrite=T)

noquote("trigger:output:output_map")
noquote("trigger:progress:100")
