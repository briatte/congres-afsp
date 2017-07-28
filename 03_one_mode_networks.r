library(dplyr)
library(igraph)
library(ggplot2)
library(ggraph)
library(readr)
library(stringr)

p <- read_tsv("data/participants.tsv", col_types = "cccc") %>% 
  select(i, j, role)

# load only organisers, chairs/discussants and participants to 'ST' panels
d <- read_csv("data/edges.csv", col_types = "icciiiiccc") %>%
  left_join(p, by = c("i", "j")) %>% # add roles
  filter(str_detect(j, "_ST(.*)"), role %in% c("c", "d", "o", "p"))

l <- c("Participant(e) mono-panel", "Participant(e) multi-panels")

for (y in unique(d$year)) {
  
  e <- filter(d, year == y)
  
  # make sure all panels have 1+ organiser(s) and 2+ participants
  w <- group_by(e, j) %>%
    summarise(n_o = sum(role == "o"), n_p = sum(role != "o")) %>%
    filter(n_p < 3 | n_o < 1 | n_o == n_p)
 
  stopifnot(!nrow(w))
  
  e <- lapply(unique(e$j), function(p) {
    expand.grid(
      i = e$i[ e$role == "o" & e$j == p ],
      j = e$i[ e$role != "o" & e$j == p ], # "c", "d", "p"
      stringsAsFactors = FALSE
    ) %>% 
      mutate(p)
  }) %>% 
    bind_rows %>% 
    group_by(p) %>% 
    mutate(weight = 1 / n_distinct(j)) # inverse weighting re: panel size
  
  # # expected left skew in edge weights
  # hist(e$weight)
  # hist(sqrt(e$weight))

  n <- graph_from_data_frame(e)
 
  E(n)$weight <- E(n)$weight / max(E(n)$weight)
  
  V(n)$size <- degree(n)
  
  # data_frame(name = V(n)$name, degree = V(n)$size) %>%
  #   arrange(-degree) %>%
  #   print
  
  e <- filter(d, year == y) %>% 
    group_by(i) %>% 
    summarise(n_p = n_distinct(j))
  
  w <- e$n_p
  names(w) <- e$i
  
  V(n)$color <- as.integer(w[ V(n)$name ])
  V(n)$color <- if_else(V(n)$color == 1, "P1", "P2+")

  ggraph(n, layout = "fr") +
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
    labs(title = str_c("Congrès AFSP ", y),
         subtitle = str_c(
           sum(V(n)$color == "P1"), " participant(e)s, ",
           sum(V(n)$color == "P2+"), " multi-panels")
    )
  
  ggsave(str_c("plots/congres-afsp", y, "-1mode.pdf"), width = 8, height = 9)
  ggsave(str_c("plots/congres-afsp", y, "-1mode.png"), width = 8, height = 9, dpi = 150)
  
  cat("\nYear", y, ":", components(n)$no, "components\n")
  print(table(V(n)$color))
  
}

# kthxbye
