noquote("trigger:progress:0")
library("rgdal", lib="~/R_libs/")
noquote("trigger:progress:50")
args = commandArgs(trailingOnly=TRUE)
path <- file.path(args[1],"a")
# path <- file.path(args[1],"dhm_zh_10m.tif")
gdal_info <- GDALinfo(path)

print(gdal_info)
output_path <- file.path(args[1],"b")

sink(output_path)
print(gdal_info)
sink()

noquote("trigger:output:b")
noquote("trigger:progress:100")