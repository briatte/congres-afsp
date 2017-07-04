library(dplyr)
library(readr)
library(stringr)

dir.create("data", showWarnings = FALSE)
dir.create("html", showWarnings = FALSE)

# ==============================================================================
# DATA
# ==============================================================================

y <- c("http://www.afsp.info/congres/congres-2017/index/",
  "http://www.afsp.info/archives/congres/congres2015/indexcongres.html",
  "http://www.afsp.info/archives/congres/congres2013/indexducongres.html",
  "http://www.afsp.info/archives/congres/congres2011/programme/index.html",
  "http://www.afsp.info/archives/congres/congres2009/programmes/indexnoms.html")

d <- data_frame()

cat("Parsing indexes for", length(y), "conferences:\n\n")
for (i in rev(y)) {
  
  f <- str_c("html/", str_extract(i, "\\d{4}"), ".html")
  if (!file.exists(f)) {
    download.file(i, f, mode = "wb", quiet = TRUE)
  }
  
  cat("", f)
  f <- read_lines(f) %>% 
    # AD   : ? (2015, 2017)
    # CP   : plénière, pas toujours numérotée (toutes éditions)
    # MD   : module disciplinaire (2009)
    # MPP  : module professionnel (2013)
    # MTED : ? (2015)
    # ST : section thématique (toutes éditions), parfois numérotées DD.D
    str_subset("(AD|MD|MPP|MTED|ST)\\s?\\d|\\sCP") %>%
    # transliterate, using sub to keep strings with non-convertible bytes
    iconv(to = "ASCII//TRANSLIT", sub = " ") %>%
    # remove diacritics
    str_replace_all("[\"^'`\\.]|&#8217;|&(l|r)squo;", "") %>%
    # remove loose HTML tags
    str_replace_all("<br\\s?/?>|<(p|b|li|span)(.*?)>|</(p|b|li|span)>", "") %>%
    # fix spaces (keep before next)
    str_replace_all("(\\s|&nbsp;)+", " ") %>% 
    # &eacute, &icirc -> e, i
    str_replace_all("&(\\w{1})(.*?);", "\\1") %>% 
    # lone initials
    str_replace_all("\\s[A-Za-z]{1}\\s", " ") %>% 
    str_trim %>% 
    data_frame(year = str_extract(f, "\\d{4}"), i = .)
  
  cat(":", nrow(f), "lines\n")
  d <- rbind(d, f)
  
}

# make sure that every row has at least one comma
d$i <- str_replace(d$i, "([a-z]+)\\s(AD|CP|MD|MPP|MTED|ST)", "\\1, \\2") %>% 
  str_to_upper

# rows with ';' are all false positives, as are rows without ','
d <- filter(d, str_detect(i, ","), !str_detect(i, ";|^\\("))

# real counts for comparison (established by hand):
# 2009 = 725 (got all)
# 2013 = 862 (got all)
# 2017 = 756 (missing 2)
cat("\nAttendees per conference:\n")
print(table(d$year))

# how many participations in a single conference?
table(str_count(d$i, ","))

# ==============================================================================
# EDGES
# ==============================================================================

# add year to panel ids and coerce to (year, i, j) data frame
d <- mapply(function(year, i) {
  x <- unlist(str_split(i, ",\\s?"))
  x[ -1 ] <- str_replace_all(x[ -1 ], "\\s+", "") # ST 0 -> ST0
  str_c(x[ 1 ], "::", str_c(year, "_", x[ -1 ])) # NAME : YEAR_ST0, ST1, ...
}, d$year, d$i) %>% 
  unlist %>% 
  as.vector %>% 
  lapply(function(x) {
    data_frame(
      year = str_extract(x, "\\d{4}"), # year
      i = str_extract(x, "(.*)::"),    # attendee
      j = str_extract(x, "::(.*)")     # panel
    )
  }) %>% 
  bind_rows %>% 
  mutate_at(2:3, str_replace, pattern = "::", replacement = "") %>% 
  distinct # safety (avoid duplicate rows)

# finalize names

# (1) remove composed family names to avoid married 'x-y' duplicates
d$i <- str_replace(d$i, "^(\\w+)-(.*)\\s", "\\1 ")

# remove 6 problematic rows
# filter(d, !str_detect(i, " "))
d <- filter(d, str_detect(i, "\\s"))

# (2) remove dashes to avoid 'marie claude' and 'marie-claude' duplicates
d$i <- str_replace_all(d$i, "-", " ")

# how many participations over the 5 conferences?
t <- group_by(d, i) %>% 
  summarise(n_conf = n_distinct(year)) %>% 
  arrange(-n_conf)

table(t$n_conf) # ~ 30 attendees went to all conferences, 1,800+ went to only 1
table(t$n_conf > 1) / nrow(t) # 72% attended only 1 conference in 8 years

# number of panels overall
n_distinct(d$j)

# number of panels in each conference
cat("\nPanels per conference:\n\n")
print(tapply(d$j, d$year, n_distinct))

# add number of panels attended per conference (useful for edge weighting)
d <- summarise(group_by(d, year, i), n_papc = n()) %>% 
  inner_join(d, ., by = c("year", "i"))

# add number of conferences attended (useful for vertex subsetting)
d <- summarise(group_by(d, i), n_conf = n_distinct(year)) %>% 
  inner_join(d, ., by = "i")

write_csv(d, "data/edges.csv")
cat("\nSaved", nrow(d), "rows,", n_distinct(d$i), "attendees,", n_distinct(d$j), "panels.")

# kthxbye
