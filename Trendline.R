# Trendline.R
# ──────────────────────────────────────────────────────────────────────────────
# Plot multi‐country GHI score trends (2000 → 2008 → 2016 → 2024)
# ──────────────────────────────────────────────────────────────────────────────

# 1. Load packages
library(readxl)
library(tidyverse)
library(janitor)
library(scales)

# 2. Read in the “2024 GHI Scores” sheet, skipping the first two rows
scores_raw <- read_excel(
  path  = "2024.xlsx",
  sheet = "2024 GHI Scores",
  skip  = 2
)

# 3. Clean up names & select only the columns we need
scores <- scores_raw %>%
  clean_names() %>%
  select(
    country    = country_with_data_from,
    score_2000 = x2000_98_02,
    score_2008 = x2008_06_10,
    score_2016 = x2016_14_18,
    score_2024 = x2024_19_23
  )

# 4. Pivot from wide → long, extract numeric year, ensure numeric & round
scores_long <- scores %>%
  pivot_longer(
    cols      = starts_with("score_"),
    names_to  = "year",
    values_to = "ghi_score"
  ) %>%
  mutate(
    year      = parse_number(year),
    ghi_score = as.numeric(ghi_score),
    ghi_score = round(ghi_score, 1)
  )
# 5. Choose countries
countries_to_plot <- c(
  "Bangladesh", "India", "Ethiopia", "Brazil", "United States", "Indonesia",
  "Mexico", "Kenya", "DR Congo",
  "Afghanistan"
)

plot_data <- scores_long %>%
  filter(country %in% countries_to_plot)

# 6. Build the trend‐line plot
p <- ggplot(plot_data, aes(x = year, y = ghi_score, color = country, group = country)) +
  # Geoms
  geom_line(size = 1.2) +
  geom_point(size = 2) +
  
  # Axes
  scale_x_continuous(
    breaks = c(2000, 2008, 2016, 2024),
    labels = c("2000", "2008", "2016", "2024")
  ) +
  scale_y_continuous(labels = scales::label_number(accuracy = 0.1)) +
  
  # Labels
  labs(
    title    = "Global Hunger Index: 2000–2024 Trends",
    x        = "Year",
    y        = "GHI Score",
    color    = "Country",
    caption  = "Source: GHI 2024"
  ) +
  
  # Theme & palette
  theme_bw(base_size = 14) +
  scale_color_brewer(palette = "Dark2") +
  theme(
    # Grids
    panel.grid.major   = element_blank(),
    panel.grid.minor   = element_blank(),
    
    # Legend
    legend.position    = "right",
    legend.background  = element_blank(),
    legend.key         = element_blank(),
    legend.title       = element_text(size = 12, face = "bold"),
    legend.text        = element_text(size = 10),
    
    # Text elements
    plot.title         = element_text(size = 16, face = "bold", hjust = 0),
    plot.caption       = element_text(size = 9, color = "grey40", hjust = 1),
    
    # Axis text
    axis.title         = element_text(size = 12),
    axis.text          = element_text(size = 10),
    
    # Margins
    plot.margin        = margin(t = 15, r = 15, b = 15, l = 15)
  )
p + theme_bw(base_family = "Arial")

# 7. Render & save
print(p)

# 8. Save a high‐res PNG (make sure “outputs/” exists)
ggsave(
  filename = "outputs/ghi_trendlines.png",
  plot     = p,
  width    = 8,
  height   = 5,
  dpi      = 300
)
ggsave("outputs/ghi_trendlines_final.png", p, width = 8, height = 5, units = "in", dpi = 300)
