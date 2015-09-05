##Point pattern analysis=group
##points=vector
##covariate=vector
##covariate_name=string mandatory_covariate_name_(no_spaces)
##x_label=string
##plot_name=string
##legend_position=string float

library(spatstat)
library(maptools)
library(rpanel)

if (covariate_name == "") {
rp.messagebox('covariate name must not be emply!', title = 'oops!')}

else {
S <- points
SP <- as(S, "SpatialPoints")
P <- as(SP, "ppp")

r <- covariate
rp <- as.psp(r)


rdist <- distfun(rp)

plot(rhohat(P, rdist, covname=covariate_name), xlab= x_label,
legendpos = legend_position,
legendargs=list(bg="transparent"),
main = plot_name)
##showplots
}
