noquote("trigger:progress:0")

args <- commandArgs(trailingOnly = TRUE)

outputPath <- file.path(args[1],"report")

outputConn <- file(outputPath, open = "wt")

sink(file = outputConn, type = "message")

require(raster, lib="~/R_libs/")
require(rgdal, lib="~/R_libs/")
require(sp, lib="~/R_libs/")
require(igraph, lib="~/R_libs/")
require(gdistance, lib="~/R_libs/")
require(rgeos, lib="~/R_libs/")

sink()

noquote("trigger:output:report")
noquote("trigger:progress:100")
