library(tidyverse)
library(igraph)
library(ggraph)
library(graphlayouts)
library(backbone) # arXiv:1912.12779v1

# load adjacency matrices built by script 02
load("data/2mode.rda")

for (i in ls(pattern = "^a\\d{4}")) {
  
  cat("\nEdge weights for year", str_remove(i, "\\D"), ":\n")
  
  # two-mode adj. matrix
  A <- get(i)
  
  # one-mode projection
  G <- A %*% t(A)
  diag(G) <- 0
  print(table(G))
  
  # backbone from one-mode and two-mode projections
  bb <- backbone::universal(G, upper = 1)
  bb2 <- backbone::universal(A, upper = 1, bipartite = TRUE)
  stopifnot(all.equal(bb$backbone, bb2$backbone))
  
  assign(str_replace(i, "a", "bb"), bb)
  print(bb$summary)
  
  # get graph as tibble
  G_df <- igraph::graph_from_adjacency_matrix(G, diag = FALSE) %>% 
    igraph::as_data_frame() %>% 
    as_tibble()
  
  # get backbone as tibble
  bb_df <- bb$backbone %>% 
    graph_from_adjacency_matrix(mode = "undirected", diag = FALSE) %>% 
    igraph::as_data_frame() %>% 
    as_tibble()
  
  # identify edges that are part of the backbone
  df <- bind_rows(
    semi_join(G_df, bb_df, by = c("from", "to")) %>% 
      add_column(backbone = TRUE),
    anti_join(G_df, bb_df, by = c("from", "to")) %>% 
      add_column(backbone = FALSE)
  )

  # count edges in the backbone
  bb_edges <- filter(df, backbone == 1)
  cat("\nBackbone has", nrow(bb_edges), "edges, ")
  
  # identify and count nodes connected to the backbone
  bb_nodes <- unique(c(bb_edges$from, bb_edges$to))
  cat("connecting", length(bb_nodes), "nodes\n")
  
  # build the final graph data frame
  n_df <- graph_from_data_frame(df, directed = FALSE)
  V(n_df)$backbone_node <- V(n_df)$name %in% bb_nodes
  
  # 'trim' the graph, keeping only the largest component
  n_components <- components(n_df)
  stopifnot(first(n_components$csize) == max(n_components$csize))
  n_df <- igraph::delete_vertices(n_df, which(n_components$membership != 1))
  
  cat(
    "Visualizing, removing",
    sum(n_components$membership != 1),
    "nodes not connected to main component\n"
  )
  
  # visualize with stress majorization
  g <- n_df %>% 
    ggraph(layout = "stress", bbox = 20) +
    geom_edge_link(color = "grey75", alpha = 2/3) +
    geom_edge_link(aes(alpha = backbone), color = "tomato3", show.legend = FALSE) +
    geom_node_point(aes(alpha = backbone_node, color = backbone_node), show.legend = FALSE) +
    scale_edge_alpha_manual("", values = c("FALSE" = 0, "TRUE" = 1)) +
    scale_alpha_manual("", values = c("FALSE" = 2/3, "TRUE" = 1)) +
    scale_color_manual("", values = c("FALSE" = "black", "TRUE" = "tomato3")) +
    theme_graph(base_family = "Helvetica", base_size = 14) +
    theme(
      legend.text = element_text(size = rel(1)),
      # legend.position = "bottom",
      plot.caption = element_text(size = rel(.85), hjust = 0.5),
      plot.title = element_text(hjust = 0.5),
      plot.subtitle = element_text(hjust = 0.5)
    ) +
    labs(
      title = str_c("Backbone of AFSP Meeting ", str_remove(i, "\\D")),
      subtitle = str_c(
        "Backbone has",
        nrow(bb_edges),
        "edges, inter-connecting",
        length(bb_nodes),
        "nodes out of",
        n_distinct(c(df$from, df$to)), # because `df` has been 'trimmed'
        sep = " "
      ),
      caption = str_c(
        "Universal backbone at upper threshold 1 ",
        "(2+ panel co-attendances)\n",
        "Disconnected graph components omitted from figure"
      )
    )

  assign(str_replace(i, "a", "bbplot"), g)
  
  ggsave(
    str_c("plots/congres-afsp", str_remove(i, "\\D"), "-backbone.png"),
    g,
    width = 8,
    height = 9
  )
  
  cat("\n")

}

# kthxbye
