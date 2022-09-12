output_path <- file.path(args[1],"report")
sink(output_path)

noquote("trigger:progress:0")

# library(raster, lib="~/R_libs/")
# library(rgdal, lib="~/R_libs/")
# library(sp, lib="~/R_libs/")
# library(igraph, lib="~/R_libs/")
# library(gdistance, lib="~/R_libs/")
# library(rgeos, lib="~/R_libs/")
require(raster, lib="~/R_libs/")
require(rgdal, lib="~/R_libs/")
require(sp, lib="~/R_libs/")
require(igraph, lib="~/R_libs/")
require(gdistance, lib="~/R_libs/")
require(rgeos, lib="~/R_libs/")

sink()

noquote("trigger:output:report")
noquote("trigger:progress:100")
