#ecosystem services script for NatCapCH Tool
#updated: 2021-12-23
#ETH Zürich
#Future Cities Lab Global www.fcl.ethz.ch
#contact: Jens Fischer jefische@ethz.ch

#-----------------------------------------#
#updated: 2022-05-02 
#contact: Laura Schalbetter schalaur@ethz.ch
#-----------------------------------------#

###------------------------------------###
#   Ecosystem service: AIR TEMPERATURE   #
###------------------------------------###


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
args <- commandArgs(trailingOnly = TRUE)

selectedGeotiffPath <- file.path(args[1],"input_map")
laiPath <- file.path(args[1],"lai_zh_10m")
parksPath <- file.path(args[1],"park10_2")
demPath <- file.path(args[1], "demand_new11")
normmargwilPath <- file.path(args[1], "normmargwil")

# outputs
airtemperature_output_name <- "air-temperature.tif"
marwildiff_output_name <- "marwildiff.tif"
value_output_name <- "value"

airtemperaturePath <- file.path(args[1], airtemperature_output_name)
marwildiffPath <- file.path(args[1], marwildiff_output_name)
valuePath <- file.path(args[1], value_output_name)

#---------------------------------------------------------------
#---------------------------------------------------------------


### prepare input data ###


# import data needed


# # land cover map (based on Bo_Fl vector layers, City of Zurich, Amtliche Vermessung, converted to 1m raster)
lcm <- raster(selectedGeotiffPath) #"lcm_zh_1m.tif"
#lcm <- raster("exportnew/lcm_zh_1m_forest.tif") #test locally 

#aggregate land cover map from 1m cell size to 10m cell size
lcm10 <- aggregate(lcm, fact=10)

# # lai map
lai <- raster(laiPath)
#lai <- raster("exportnew/lai_zh_10m.tif") #test locally 

## ---- imports for willingsness to pay ---- ## 
## import park of city 
parks <- raster(parksPath)
#parks <- raster("exportnew/park10_2.tif")#test locally 

## import demand
dem <- raster(demPath)
#dem <- raster("exportnew/demand_new11.tif")#test locally

# import "norm" Marginal willingeness to pay (landcover)
normmargwil <- raster(normmargwilPath)
#normmargwil <- raster("exportnew/normmargwil.tif")#test locally 

normmargwilraster <- lcm10
normmargwilraster[,]<-0
values(normmargwilraster) <- values(normmargwil) 

#---------------------------------------------------------------
#---------------------------------------------------------------
noquote("trigger:progress:25")
### calculations ###

# add a function for the buffering
# this function draws a circle in a matrix and you can set the radius
drawImage <- function(mat, center, radius) {
  grid <- mat
  x.index <- round(center + radius * cos(seq(0, 2*pi, length = 360)))
  y.index <- round(center + radius * sin(seq(0, 2*pi, length = 360)))
  
  xyg <- data.frame(xind = round(center + radius * cos(seq(0, 2*pi, length = 360))),
                    yind =round(center + radius * sin(seq(0, 2*pi, length = 360))))
  
  for (i in seq(x.index)){
    
    fg <- range(xyg$yind[which(xyg$xind == xyg$xind[i])])
    grid[xyg$xind[i], fg[1]:fg[2]]<- 1
  }
  grid
  #image(grid)
}  # end drawImage


### buffer for 10m resolution maps
# create buffer matrix - approximately a 50m buffer
buffer50 <- drawImage(matrix(0, 11, 11), 6, 5)  # call example

# create buffer matrix - approximately a 100m buffer
buffer100 <- drawImage(matrix(0, 21, 21), 11, 10)  # call example

# create buffer matrix - approximately a 200m buffer
buffer200 <- drawImage(matrix(0, 41, 41), 21, 20)  # call example


# this sets up a new raster stack with single layers for the different vegetation types
# lcm10empty <- lcm10
# lcm10empty[,]<-0
# lcm10empty <- stack(lcm10empty,lcm10empty,lcm10empty,lcm10empty,lcm10empty)
# lcmdisag[[1]][lcm10 == 28| lcm10 == 34| lcm10 == 41| lcm10 == 42] <- 1 # wetland and mangrove -> #Wetland & #Schilfguertel & #Mangrove & #Freshwater swamp forest
# lcmdisag[[2]][lcm10 == 35| lcm10 == 38| lcm10 == 21| lcm10 == 31] <- 1 # unmanaged -> #Forest & #uebrige_bestockte & #Unmanaged green & #andere_humusierte
# lcmdisag[[3]][lcm10 == 39] <- 1 # managed #Managed trees
# lcmdisag[[4]][lcm10 == 25| lcm10 == 24| lcm10 == 29| lcm10 == 26| lcm10 == 23| lcm10 == 27| lcm10 == 22] <- 1 # grass -> #Managed green & #Hausumschwung_humusiert & #Verkehrsteilerflaeche & #Sportanlage & #uebrige_Intensivkultur & #Friedhof & #Reben
# lcmdisag[[5]][lcm10 == 33| lcm10 == 32| lcm10 == 16| lcm10 == 40] <- 1 # water -> #Water course & #Water course & #Wasserbecken & #Marine

lcmdisagwetland <- lcm10
lcmdisagwetland[,]<-0
lcmdisagwetland[lcm10 == 28| lcm10 == 34| lcm10 == 41| lcm10 == 42] <- 1 # wetland and mangrove -> #Wetland & #Schilfguertel & #Mangrove & #Freshwater swamp forest

lcmdisagunmanaged<- lcm10
lcmdisagunmanaged[,]<-0
lcmdisagunmanaged[lcm10 == 35| lcm10 == 38| lcm10 == 21| lcm10 == 31] <- 1 # unmanaged -> #Forest & #uebrige_bestockte & #Unmanaged green & #andere_humusierte

lcmdisagmanaged<- lcm10
lcmdisagmanaged[,]<-0
lcmdisagmanaged[lcm10 == 39] <- 1 # managed #Managed trees

lcmdisaggrass<- lcm10
lcmdisaggrass[,]<-0
lcmdisaggrass[lcm10 == 25| lcm10 == 24| lcm10 == 29| lcm10 == 26| lcm10 == 23| lcm10 == 27| lcm10 == 22] <- 1 # grass -> #Managed green & #Hausumschwung_humusiert & #Verkehrsteilerflaeche & #Sportanlage & #uebrige_Intensivkultur & #Friedhof & #Reben

lcmdisagwater <- lcm10
lcmdisagwater[,]<-0
lcmdisagwater[lcm10 == 33| lcm10 == 32| lcm10 == 16| lcm10 == 40] <- 1 # water -> #Water course & #Water course & #Wasserbecken & #Marine


# this applies the buffer (focal stats) across each layer
# to calculate the % cover of the veg types, and the mean LAI
# lcmdisag[[1]] <- focal(lcmdisag[[1]], buffer200, mean)
# lcmdisag[[2]] <- focal(lcmdisag[[2]], buffer200, mean)
# lcmdisag[[3]] <- focal(lcmdisag[[3]], buffer50, mean)
#lcmdisag[[4]] <- focal(lcmdisag[[4]], buffer10, mean)
# lcmdisag[[5]] <- focal(lcmdisag[[5]], buffer100, mean)

lcmdisagwetland <- focal(lcmdisagwetland, buffer200, mean)
lcmdisagunmanaged <- focal(lcmdisagunmanaged, buffer200, mean)
lcmdisagmanaged <- focal(lcmdisagmanaged, buffer50, mean)
#lcmdisaggrass <- focal(lcmdisag[[4]], buffer10, mean)
lcmdisagwater <- focal(lcmdisagwater, buffer100, mean)


# add lai
lai <- focal(lai, buffer100, mean,na.rm=T)
noquote("trigger:progress:50")
# lcmdisag <- stack(lcmdisag, projectRaster(lai,lcmdisag))

# lcmdisag <- stack(lcmdisag, lai)

# names(lcmdisag) <- c("wetland200", "unmanaged200", "managed50", "grass100", "water0", "lai100")


# merge all unmanaged
# lcmdisag$unmanaged200T <- lcmdisag$unmanaged200 + lcmdisag$wetland200

lcmdisagunmanagednew <- lcmdisagunmanaged + lcmdisagwetland

# check that the values do not exceed the ranges from the data
# lcmdisag$unmanaged200T[lcmdisag$unmanaged200T < 0 ]<- 0
# lcmdisag$unmanaged200T[lcmdisag$unmanaged200T > 0.479 ]<- 0.479 #not confirmed where this number comes from
# lcmdisag$managed50[lcmdisag$managed50 < 0] <- 0
# lcmdisag$managed50[lcmdisag$managed50 > 0.545] <- 0.545 #not confirmed where this number comes from

lcmdisagunmanagednew[lcmdisagunmanagednew < 0 ]<- 0
lcmdisagunmanagednew[lcmdisagunmanagednew > 0.479 ]<- 0.479 #not confirmed where this number comes from
lcmdisagmanaged[lcmdisagmanaged < 0] <- 0
lcmdisagmanaged[lcmdisagmanaged > 0.545] <- 0.545 #not confirmed where this number comes from


# values given in "air temperature modelling overview - generalised additive model fixed effect coefficients" 
# tempdif <-   #intercept
# ((lcmdisag$unmanaged200T)* -2.4634) +
# (lcmdisag$managed50 * -1.5090) +
# (lcmdisag$lai100 * -0.9870) 

tempdif <-   #intercept
  ((lcmdisagunmanagednew)* -2.4634) +
  (lcmdisagmanaged * -1.5090) +
  (lai * -0.9870) 


tempdif[is.na(lcm10$lcm_zh_1m)] <- NA
#tempdif[lcm10$lcm_zh_1m == 1|lcm10$lcm_zh_1m == 2|lcm10$lcm_zh_1m == 3|lcm10$lcm_zh_1m == 4|lcm10$lcm_zh_1m == 5|
#          lcm10$lcm_zh_1m == 6|lcm10$lcm_zh_1m == 7|lcm10$lcm_zh_1m == 8|lcm10$lcm_zh_1m == 9|lcm10$lcm_zh_1m == 10|
#          lcm10$lcm_zh_1m == 11|lcm10$lcm_zh_1m == 12|lcm10$lcm_zh_1m == 13|lcm10$lcm_zh_1m == 14|lcm10$lcm_zh_1m == 15] <- NA


#---------------------------------------------------------------
#---------------------------------------------------------------

## Marginal willingness to pay -- > 5.2.3.5 Societal and economic valuation of temperature reduction 

# get all green spaces in the city
lcm10green <- lcm10
lcm10green[,]<-0
lcm10green[lcm10 == 28| lcm10 == 34| lcm10 == 41| lcm10 == 42 | lcm10 == 35| lcm10 == 38| lcm10 == 21| lcm10 == 31 | lcm10 == 39 | lcm10 == 25| lcm10 == 24| lcm10 == 29| lcm10 == 26| lcm10 == 23| lcm10 == 27| lcm10 == 22] <- 1 # all green spaces

# get all park areas (1 = park, 0 = no park)
lcm10parks <- lcm10
lcm10parks[,]<-0
values(lcm10parks) <- values(parks) # parks

# greenpark = 1 --> no park + green in lcm ; greenpark = 2 --> park + green in lcm
lcm10greenpark <- lcm10green + lcm10parks

# neighboorhood green spaces 
neigh <- lcm10
neigh[,]<-0
neigh[lcm10greenpark == 1] <- 1 # neighbourhood green spaces

# official parks 
terpar <- lcm10
terpar[,]<-0
terpar[lcm10greenpark == 2] <- 1 # terresitrial parks

# temperature differences: (-1°; -2°; -3°)
tempdif1 <- lcm10
tempdif1[,]<-0
tempdif1[(tempdif> -2) & (tempdif<= -1)] <- 1

tempdif2 <- lcm10
tempdif2[,]<-0
tempdif2[(tempdif> -3) & (tempdif<= -2)] <- 1

tempdif3 <- lcm10
tempdif3[,]<-0
tempdif3[tempdif <= -3] <- 1

#tempdif1 <- tempdif1 - tempdif2- tempdif3 
#tempdif2 <- tempdif2 - tempdif3 
noquote("trigger:progress:75")
# demand (given from Marcelos Paper about Covid)
demlayer <- lcm10parks
demlayer[,] <- 0
values(demlayer) <- values(dem)

#Calculation of the marginal willingness to pay for 1 2 and 3° reduction 
marwilneigh1 <- neigh * 5.01 * 30 * demlayer * tempdif1
marwilterpar1 <- terpar * 5.58 * 30 * demlayer * tempdif1

marwilneigh2 <- neigh * 8.0 * 30 * demlayer  * tempdif2
marwilterpar2 <- terpar * 5.0 * 30 * demlayer * tempdif2

marwilneigh3 <- neigh * 12.63 * 30 * demlayer  * tempdif3
marwilterpar3 <- terpar * 4.44 * 30 * demlayer * tempdif3

marwiltot <- marwilneigh1 + marwilterpar1 + marwilneigh2 + marwilterpar2 + marwilneigh3 + marwilterpar3 
marwildiff <- round(marwiltot - normmargwilraster)
marwildiff[is.na(lcm10)] <- NA

value <- cellStats(marwildiff, 'sum')
value <- round(value)
#---------------------------------------------------------------
#---------------------------------------------------------------


# save output map
# save it out
writeRaster(tempdif, airtemperaturePath, overwrite=T)
noquote(paste("trigger:output:", airtemperature_output_name, sep=""))
writeRaster(marwildiff, marwildiffPath, overwrite=T)
noquote(paste("trigger:output:", marwildiff_output_name, sep=""))
write(value, valuePath)
noquote(paste("trigger:output:", value_output_name, sep=""))

noquote("trigger:progress:100")

# output test locally 
#writeRaster(tempdif1, "output/tempdif1.tif", overwrite=T)
#writeRaster(tempdif2, "output/tempdif2.tif", overwrite=T)
#(tempdif3, "output/tempdif3.tif", overwrite=T)
#writeRaster(marwiltot, "output/marwiltot.tif", overwrite=T)
#writeRaster(tempdif, "output/air-temperature.tif", overwrite=T)
#writeRaster(marwildiff, "output/marwildiff.tif", overwrite=T)
#write(value, "output/value.txt")

