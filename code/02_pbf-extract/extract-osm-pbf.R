library(tidyverse)
library(sf)

conflicted::conflicts_prefer(dplyr::filter)

# Load data
shape_data <- read_csv("data/gtfs_feeds/wmata/shapes.txt")

# Convert to simple features object so we can extract the bounding box with
# st_bbox()

shape_sf <- shape_data |>
	sf::st_as_sf(coords = c("shape_pt_lon", "shape_pt_lat"), crs = "OGC:CRS84")

bounding_box <- shape_sf |>
	st_bbox()
