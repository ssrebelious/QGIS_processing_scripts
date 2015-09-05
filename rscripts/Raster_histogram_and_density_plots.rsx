##layer=raster
##Raster processing=group
##dens_or_hist=string hist
##showplots
library(rpanel)
library(rasterVis)
str <- dens_or_hist
if (str !='dens' & str != 'hist'){
rp.messagebox('you must enter "dens" or "hist"', title = 'oops!')
} else {
if (nbands(layer) == 1) {
layer <- as.matrix(layer)
layer <- raster(layer)
}
if (str == 'dens') {
densityplot(layer)
} else if (str == 'hist') {
histogram(layer)
}
}
