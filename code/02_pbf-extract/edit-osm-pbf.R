# Remove private access designations within DC that stops some accurate routing
# Needed as some addresses are in restricted areas and ORS respects the tags

# TODO put this in a shell script

system2(
	"osmium",
	args = c(
		"cat",
		"data/osm_extracts/wmata-extract-from-geofabrik_us-south-latest.osm.pbf",
		"-o data/osm_extracts/wmata-extract-from-geofabrik_us-south-latest.osm.opl",
		"--overwrite"
	)
)

system2(
	"sed",
	args = c(
		"-i ''",
		"s/access=private/access=yes/g",
		"data/osm_extracts/wmata-extract-from-geofabrik_us-south-latest.osm.opl"
	)
)

system2(
	"sed",
	args = c(
		"-i ''",
		"s/foot=private/foot=yes/g",
		"data/osm_extracts/wmata-extract-from-geofabrik_us-south-latest.osm.opl"
	)
)

system2(
	"sed",
	args = c(
		"-i ''",
		"s/motor_vehicle=private/motor_vehicle=yes/g",
		"data/osm_extracts/wmata-extract-from-geofabrik_us-south-latest.osm.opl"
	)
)

system2(
	"sed",
	args = c(
		"-i ''",
		"s/access=military/access=yes/g",
		"data/osm_extracts/wmata-extract-from-geofabrik_us-south-latest.osm.opl"
	)
)

system2(
	"osmium",
	args = c(
		"cat",
		"data/osm_extracts/wmata-extract-from-geofabrik_us-south-latest.osm.opl",
		"-o data/osm_extracts/edited-wmata-extract-from-geofabrik_us-south-latest.osm.pbf",
		"--overwrite"
	)
)
