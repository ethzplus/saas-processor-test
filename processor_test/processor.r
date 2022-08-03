print("trigger:progress:0")
library("rgdal", lib="~/R_libs/")
print("trigger:progress:50")
args = commandArgs(trailingOnly=TRUE)
path <- file.path(args[1],"a")
# path <- file.path(args[1],"dhm_zh_10m.tif")
gdal_info <- GDALinfo(path)

sink("b")
print(gdal_info)
sink()

print("trigger:output:b")
print("trigger:progress:100")