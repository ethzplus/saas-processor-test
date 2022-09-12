output_path <- file.path(args[1],"report")

noquote("trigger:progress:0")

sink(output_path)

list.dirs("~/R_libs/", recursive=FALSE)

sink()

noquote("trigger:output:report")
noquote("trigger:progress:100")
