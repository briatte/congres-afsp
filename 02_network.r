library(dplyr)
library(igraph)
library(readr)

d <- read_csv("data/edges.csv", col_types = "iccii")

# ==============================================================================
# INCIDENCE MATRIX
# ==============================================================================

m <- matrix(0, nrow = n_distinct(d$i), ncol = n_distinct(d$j))

dim(m) # ~ 2,500 x 360
stopifnot(object.size(m) / 10^6 < 10) # ~ 7 MB, no need to sparse it up

rownames(m) <- unique(d$i)
colnames(m) <- unique(d$j)

for (i in colnames(m)) {
  m[ rownames(m) %in% d$i[ d$j == i ], i ] <- 1
}
rowSums(m) # number of panel participations per person (includes self-loops!)
colSums(m) # number of persons per panel

# ==============================================================================
# ONE-MODE ADJACENCY MATRIX
# ==============================================================================

# unweighted, undirected one-mode adjacency matrix of attendees
a <- m %*% t(m)
diag(a) <- NA # self-loops

stopifnot(isSymmetric(a))
hist(rowSums(a, na.rm = TRUE)) 

# unweighted, undirected
n <- network(a, directed = FALSE)

# not really dense, right
network.density(n)

# strange degree distribution
set.vertex.attribute(n, "degree", sna::degree(n, gmode = "graph"))
summary(n %v% "degree")
hist(n %v% "degree")

network.vertex.names(n)[ n %v% "degree" > 100 ] # hello friends
network.vertex.names(n)[ n %v% "degree" > 150 ] # hey most central dude

# plot with n_conferences
x <- d$n_c
names(x) <- d$i

set.vertex.attribute(n, "n_c", x[ network.vertex.names(n) ])
set.vertex.attribute(n, "color", c("grey", "lightyellow", "gold", "tomato", "red")[ n %v% "n_c"])
plot(n, vertex.col = n %v% "color", edge.col = "grey50", label = "vertex.names")
