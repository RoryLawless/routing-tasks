# Get latest GTFS data from WMATA API
# This get the combined GTFS feed for all WMATA services

library(httr2)

# Set up API key and endpoint
# Read API key from 1password vault using secret reference stored in environment
# variable

api_key <- Sys.getenv("WMATA_API")

# Prefix to use for downloaded zip name

save_date <- Sys.Date()

# Function to download GTFS data
download_gtfs <- function(
	api_key,
	url = "https://api.wmata.com/gtfs/rail-bus-gtfs-static.zip",
	save_prefix = "wmata"
) {
	require(httr2)
	require(glue)

	save_name <- glue("data/gtfs_feeds/{save_prefix}-rail-bus-gtfs-static.zip")
	httr2::request(url) |>
		req_headers_redacted(
			"Cache-Control" = "no-cache",
			"api_key" = api_key
		) |>
		req_perform(path = save_name)
}

# Download GTFS data
download_gtfs(api_key, save_prefix = save_date)

# Optionally extract to gtfs_feeds/wmata
unzip(
	glue("data/gtfs_feeds/{Sys.Date()}-rail-bus-gtfs-static.zip"),
	exdir = "data/gtfs_feeds/wmata/"
)
