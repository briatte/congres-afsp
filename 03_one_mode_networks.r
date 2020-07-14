library(tidyverse)
library(igraph)
library(ggraph)
library(graphlayouts)

p <- readr::read_tsv("data/participants.tsv", col_types = "cccc") %>% 
  select(i, j, role)

# load only organisers, chairs/discussants and participants to 'ST' panels
d <- readr::read_tsv("data/edges.tsv", col_types = "icciiiiccc") %>%
  left_join(p, by = c("i", "j")) %>% # add roles
  filter(str_detect(j, "_ST(.*)"), role %in% c("c", "d", "o", "p"))

# l <- c("Participant(e) mono-panel", "Participant(e) multi-panels")
l <- c("Mono-panel participant", "Multi-panel participant")

for (y in unique(d$year)) {
  
  e <- filter(d, year == y)
  
  # make sure all panels have 1+ organiser(s) and 2+ participants
  w <- group_by(e, j) %>%
    summarise(n_o = sum(role == "o"), n_p = sum(role != "o")) %>%
    filter(n_p < 3 | n_o < 1 | n_o == n_p)
 
  stopifnot(!nrow(w))
  
  e <- purrr::map_df(unique(e$j), function(p) {
    tidyr::expand_grid( # actually twice slower than `expand.grid`...
      i = e$i[ e$role == "o" & e$j == p ],
      j = e$i[ e$role != "o" & e$j == p ] # "c", "d", "p"
    ) %>% 
      tibble::add_column(p, .before = 1)
  }) %>% 
    group_by(p) %>% 
    mutate(weight = 1 / n_distinct(j)) # inverse weighting re: panel size
  
  # expected left skew in edge weights
  # hist(e$weight)

  n <- igraph::graph_from_data_frame(e)
 
  E(n)$weight <- E(n)$weight / max(E(n)$weight)
  
  V(n)$size <- igraph::degree(n)
  
  # tibble::tibble(name = V(n)$name, degree = V(n)$size) %>%
  #   arrange(-degree) %>%
  #   print
  
  e <- filter(d, year == y) %>% 
    group_by(i) %>% 
    summarise(n_p = n_distinct(j))
  
  w <- e$n_p
  names(w) <- e$i
  
  V(n)$color <- as.integer(w[ V(n)$name ])
  V(n)$color <- if_else(V(n)$color == 1, "P1", "P2+")

  cat("\nYear", y, ":", igraph::components(n)$no, "components\n")
  print(table(V(n)$color))
  
  ggraph(n, layout = "stress") +
    geom_edge_link(aes(alpha = weight), show.legend = FALSE) +
    geom_node_point(aes(size = size, color = color), alpha = 2/3) +
    scale_color_manual("", values = c("P1" = "steelblue3", "P2+" = "tomato3"), labels = l) +
    guides(size = FALSE) +
    theme_graph(base_family = "Helvetica", base_size = 14) +
    theme(
      legend.text = element_text(size = rel(1)),
      legend.position = "bottom",
      plot.title = element_text(hjust = 0.5),
      plot.subtitle = element_text(hjust = 0.5)
    ) +
    labs(
      # title = str_c("Congrès AFSP ", y),
      title = str_c("AFSP Meeting ", y),
      # subtitle = str_c(
      #   sum(V(n)$color == "P1"), " participant(e)s, ",
      #   sum(V(n)$color == "P2+"), " multi-panels"
      # )
      subtitle = str_c(
        sum(V(n)$color == "P1"), " participants, ",
        sum(V(n)$color == "P2+"), " multi-panels"
      )
    )
  
  ggsave(str_c("plots/congres-afsp", y, "-1mode.pdf"), width = 8, height = 9)
  ggsave(str_c("plots/congres-afsp", y, "-1mode.png"), width = 8, height = 9, dpi = 150)
  
}

# kthxbye
