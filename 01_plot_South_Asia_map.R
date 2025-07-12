# Load required libraries
library(sf)           # for reading and handling shapefiles
library(ggplot2)      # for plotting
library(readxl)       # for reading Excel files
library(dplyr)        # for data manipulation
library(countrycode)  # for converting country names to ISO3 codes
library(stringr)      # for string detection
library(ggrepel)
library(ggspatial)
# 1. Read & clean the 2024 GHI scores from the Excel file
ghi <- read_excel("2024.xlsx",
                  sheet = "2024 GHI Scores",
                  skip  = 1) %>%                       # skip the top title row
  select(
    Country   = 1,                          # first column is country name
    ghi_score = 5                           # fifth column is 2024 score
  ) %>%
  slice(-1) %>%                             # drop the repeated header row
  mutate(
    ghi_score = as.numeric(ghi_score),      # convert scores to numeric (NA for “<5”)
    keep      = !is.na(Country) &          # drop any stray note rows
      !str_detect(Country, "^Note")
  ) %>%
  filter(keep) %>%
  select(-keep) %>%
  mutate(
    ISO3 = countrycode(Country,            # add standard ISO3 codes
                       origin      = "country.name",
                       destination = "iso3c")
  )

# 2. Read and repair the Natural Earth shapefile
world_sf <- st_read("ne_10m_admin_0_countries/ne_10m_admin_0_countries.shp")
world_sf <- st_make_valid(world_sf)        # fix any invalid geometries

# 3. Join your GHI data onto the shapefile by matching ISO3 → ISO_A3
world_ghi <- world_sf %>%
  left_join(ghi, by = c("ISO_A3" = "ISO3"))

# 4. Subset to just the South Asian countries (Natural Earth SUBREGION == "Southern Asia")

south_asia <- world_ghi %>%
  filter(
    SUBREGION == "Southern Asia",
    !ADMIN %in% c("Iran", "Siachen Glacier")  # exclude these two
  )

# Now pull the unique country list
south_asia_countries <- unique(south_asia$ADMIN)
south_asia_countries

# 1) Compute centroids for labeling
south_asia_centroids <- st_centroid(south_asia)

# 2) Get simple x/y from geometry
coords <- st_coordinates(south_asia_centroids)
south_asia_centroids <- south_asia_centroids %>%
  mutate(lon = coords[,1], lat = coords[,2])

ggplot(south_asia) +
  # 1) country polygons
  geom_sf(aes(fill = ghi_score),
          color = "white",
          size  = 0.1) +
  
  # 2) repelled labels at centroids
  geom_text_repel(
    data          = south_asia_centroids,
    aes(x = lon, y = lat, label = ADMIN),
    family        = "Arial",
    size          = 3,
    box.padding   = 0.5,
    point.padding = 0.3,
    segment.size  = 0.2,
    segment.color = "grey50",
    max.overlaps  = Inf
  ) +
  
  # 3) purple→blue gradient fill
  scale_fill_gradient(
    name     = "GHI 2024",
    low      = "purple1",
    high     = "lightblue",
    na.value = "white"
  ) +
  
  # 4) zoom to bounding box
  coord_sf(
    xlim   = c(60, 100),
    ylim   = c(0, 40),
    expand = FALSE
  ) +
  
  # 5) formatted axes
  scale_x_continuous(
    breaks = seq(60, 100, by = 10),
    labels = ~ paste0(.x, "°E")
  ) +
  scale_y_continuous(
    breaks = seq(0, 40, by = 10),
    labels = ~ paste0(.x, "°N")
  ) +
  
  # add north arrow and scale bar
  annotation_north_arrow(
    location    = "tr", 
    which_north = "true",
    pad_x       = unit(0.3, "cm"),
    pad_y       = unit(0.3, "cm"),
    style       = north_arrow_fancy_orienteering()
  ) +
  annotation_scale(
    location    = "bl",
    width_hint  = 0.3,
    pad_x       = unit(0.3, "cm"),
    pad_y       = unit(0.3, "cm"),
    style       = scalebar_style_draft(
      stroke = 0.5,      # thin outline
      color  = "black",  # bar color
      fill   = c("white","black")
    )
  ) +
  
  # 6) titles, captions, and no axis labels
  labs(
    title   = "South Asia 2024",
    caption = "Data: GHI 2024 | Map: Natural Earth",
    x       = NULL,
    y       = NULL
  ) +
  
  # 7) minimal theme + beige background
  theme_minimal(base_size = 12) +
  theme(
    text                 = element_text(family = "Arial"),
    plot.title.position  = "plot",
    plot.title           = element_text(hjust = 0),
    legend.position      = "bottom",
    panel.grid.major     = element_line(color = "grey90", linetype = "dashed"),
    panel.grid.minor     = element_blank(),
    panel.background     = element_rect(fill = "beige", color = NA),
    plot.background      = element_rect(fill = "beige", color = NA),
    plot.margin          = margin(20, 20, 20, 20)
  )