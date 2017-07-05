library(dplyr)
library(igraph)
library(ggplot2)
library(ggraph)
library(readr)
library(stringr)

d <- read_csv("data/edges.csv", col_types = "icciiii")

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

rowSums(m) # number of panel attendances per person (includes self-loops)
colSums(m) # number of persons per panel

stopifnot(colSums(m) > 1) # all panels have 2+ attendees

# ==============================================================================
# SIMPLE INVERSE WEIGHTING
# ==============================================================================

w <- apply(m, 2, function(x) { x / sum(x) }) # \in (0, 0.5]

# ==============================================================================
# BIPARTITE NETWORK PLOTS
# ==============================================================================

y <- unique(str_sub(colnames(w), 1, 4))
for (i in y) {
  
  n <- w[, str_sub(colnames(w), 1, 4) == i ]
  n <- n[ rowSums(n) > 0, ]
  
  n <- graph_from_incidence_matrix(n, weighted = TRUE) %>%
    igraph::as_data_frame(.) %>% 
    mutate(year = str_sub(to, 1, 4)) %>% 
    graph_from_data_frame(directed = FALSE)
  
  E(n)$weight <- E(n)$weight / max(E(n)$weight)
  
  V(n)$type <- ifelse(str_detect(V(n)$name, "^\\d{4}"), "Panel", "Participant(e)")
  V(n)$type <- ifelse(V(n)$type == "Panel", "P0", ifelse(degree(n) > 1, "P2", "P1"))
  V(n)$size <- degree(n)
  V(n)$size <- ifelse(V(n)$type == "P0", 1.5, V(n)$size)
  
  l <- c("Panel", "Participant(e) de degré 1", "Participant(e) de degré 2+")
  
  ggraph(n, layout = "fr") +
    geom_edge_link(aes(alpha = weight), show.legend = FALSE) +
    geom_node_point(aes(size = size, shape = type, color = type), alpha = 2/3) +
    scale_shape_manual("", values = c("P0" = 15, "P1" = 19, "P2" = 19), labels = l) +
    scale_color_manual("", values = c("P0" = "grey35", "P1" = "steelblue3", "P2" = "tomato3"), labels = l) +
    guides(size = FALSE) +
    theme_graph(base_family = "Helvetica", base_size = 14) +
    theme(
      legend.text = element_text(size = rel(1)),
      legend.position = "bottom",
      plot.title = element_text(hjust = 0.5),
      plot.subtitle = element_text(hjust = 0.5)
    ) +
    labs(title = str_c("Congrès AFSP ", i),
         subtitle = str_c(
           sum(V(n)$type == "P0"), " panels, ",
           sum(V(n)$type != "P0"), " participant(e)s")
    )

  ggsave(str_c("plots/congres-afsp", i, ".pdf"), width = 8, height = 9)
  ggsave(str_c("plots/congres-afsp", i, ".png"), width = 8, height = 9, dpi = 150)

  cat("\nYear", i, ":", components(n)$no, "components\n")
  print(table(V(n)$type))
  
}

saveRDS(w, file = "data/incidence_matrix.rds")

# kthxbye
