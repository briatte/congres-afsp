library(tidyverse)
library(igraph)
library(ggraph)


# ==============================================================================
# INCIDENCE MATRIX
# ==============================================================================

m <- matrix(0, nrow = n_distinct(d$i), ncol = n_distinct(d$j))

dim(m) # ~ 2,500 x 360
stopifnot(object.size(m) / 10^6 < 15) # ~ 11 MB, no need to sparsen it

rownames(m) <- unique(d$i)
colnames(m) <- unique(d$j)

for (i in colnames(m)) {
  m[ rownames(m) %in% d$i[ d$j == i ], i ] <- 1
}

rowSums(m) # number of panel attendances per person (includes self-loops)
colSums(m) # number of persons per panel

stopifnot(colSums(m) > 1) # all panels have 2+ participants

# ==============================================================================
# SIMPLE INVERSE WEIGHTING
# ==============================================================================

w <- apply(m, 2, function(x) { x / sum(x) }) # \in (0, 0.5]

# ==============================================================================
# BIPARTITE NETWORK PLOTS
# ==============================================================================

l <- c("Panel", "Participant(e) de degré 1", "Participant(e) de degré 2+")
l <- c("Panel", "Participant with degree 1", "Participant with degree 2+")

y <- unique(str_sub(colnames(w), 1, 4))

for (i in rev(y)) {
  
  n <- w[, str_sub(colnames(w), 1, 4) == i ]
  n <- n[ rowSums(n) > 0, ]
  
  assign(str_c("a", i), n)
  
  n <- graph_from_incidence_matrix(n, weighted = TRUE) %>%
    igraph::as_data_frame(.) %>% 
    mutate(year = str_sub(to, 1, 4)) %>% 
    graph_from_data_frame(directed = FALSE)
  
  assign(str_c("g", i), n)
  
  E(n)$weight <- E(n)$weight / max(E(n)$weight)
  
  V(n)$type <- if_else(str_detect(V(n)$name, "^\\d{4}"), "Panel", "Participant(e)")
  V(n)$type <- if_else(V(n)$type == "Panel", "P0", if_else(degree(n) > 1, "P2", "P1"))
  V(n)$size <- degree(n)
  V(n)$size <- if_else(V(n)$type == "P0", 1.5, V(n)$size)
  
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
    labs(
      # title = str_c("Congrès AFSP ", i),
      title = str_c("AFSP Meeting ", i),
      subtitle = str_c(
        sum(V(n)$type == "P0"), " panels, ",
        # sum(V(n)$type != "P0"), " participant(e)s"
        sum(V(n)$type != "P0"), " participants"
      )
    )

  ggsave(str_c("plots/congres-afsp", i, "-2mode.pdf"), width = 8, height = 9)
  ggsave(str_c("plots/congres-afsp", i, "-2mode.png"), width = 8, height = 9, dpi = 150)

  cat("\nYear", i, ":", components(n)$no, "components\n")
  print(table(V(n)$type))
  
}

save(list = ls()[ str_detect(ls(), "^(a|g)\\d{4}") ], file = "data/2mode.rda")
readr::write_rds(w, "data/incidence_matrix.rds")

# kthxbye
