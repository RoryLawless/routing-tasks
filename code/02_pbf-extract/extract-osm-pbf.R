# Extract and filter pbf -------------------------------------------------

library(readr)
library(sf)
library(osmextract)
library(glue)

# Load data
shape_data <- read_csv("data/gtfs_feeds/wmata/shapes.txt")

# Convert to simple features object so we can extract the bounding box with
# st_bbox()

shape_sf <- shape_data |>
	sf::st_as_sf(coords = c("shape_pt_lon", "shape_pt_lat"), crs = "OGC:CRS84")

bounding_box <- shape_sf |>
	st_bbox()

# Get the pbf containing the bounding box
# Set to not create the filter

oe_get(
	bounding_box,
	provider = "geofabrik",
	download_directory = "data/osm_extracts",
	download_only = TRUE,
	skip_vectortranslate = TRUE
)

# Run osmium extract shell command to extract the part of the pbf file that
# corresponds with the WMATA bounding box

bbox_arg <- glue_data(bounding_box, "--bbox {xmin},{ymin},{xmax},{ymax} ")

system2(
	"osmium",
	args = c(
		"extract data/osm_extracts/geofabrik_us-south-latest.osm.pbf",
		bbox_arg,
		"-o data/osm_extracts/wmata-extract-from-geofabrik_us-south-latest.osm.pbf",
		"--overwrite"
	)
)
