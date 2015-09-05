##Point pattern analysis=group
##point_layer=vector
##simulations=number 100
##optional_plot_name=string

library(spatstat)
library(maptools)

sp <- as(point_layer, "SpatialPoints")
sp <- as(sp, "ppp")

e <- envelope(sp, Kest, nsim = simulations)
>e

plot(e, main = optional_plot_name)
##showplots
