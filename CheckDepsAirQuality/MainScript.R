output_path <- file.path(args[1],"report")
sink(output_path)

noquote("trigger:progress:0")

library(raster, lib="~/R_libs/")
library(rgdal, lib="~/R_libs/")
library(sp, lib="~/R_libs/")
library(igraph, lib="~/R_libs/")
library(gdistance, lib="~/R_libs/")
library(rgeos, lib="~/R_libs/")

sink()

noquote("trigger:output:report")
noquote("trigger:progress:100")
