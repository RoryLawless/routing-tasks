# Creates entries in calendar.txt for calendar_data.txt IDs that are currently
# missing

library(tidyverse)

conflicted::conflicts_prefer(dplyr::filter)

# Load data
calendar_data <- read_csv("data/gtfs_feeds/wmata/calendar_dates.txt")
calendar <- read_csv("data/gtfs_feeds/wmata/calendar.txt")

# Find missing service_ids
missing_service_ids <- setdiff(calendar_data$service_id, calendar$service_id)

# Convert date column to date type and find weekday for each entry
calendar_data <- calendar_data |>
	mutate(
		date = as.Date(as.character(date), format = "%Y%m%d"),
		weekday = weekdays(date)
	)

# Pivot to wide format to create columns for each weekday
calendar_data_wide <- calendar_data |>
	filter(service_id %in% missing_service_ids) |>
	pivot_wider(
		names_from = weekday,
		values_from = exception_type,
		values_fill = 0
	) |>
	select(-date) |>
	summarise(across(Tuesday:Monday, \(x) max(x, na.rm = TRUE)), .by = service_id)

# Convert exception_type values to 0/1 for calendar.txt format
# Codes in calendar_dates.txt:
# 2 = service removed
# 1 = service added
# 2 needs to be converted to 0 (service not available for all day of week) for
# calendar.txt
# Otherwise, set to 1 (service available for all day of week)
calendar_data_wide <- calendar_data_wide |>
	mutate(across(Tuesday:Monday, \(x) case_match(x, 2 ~ 0, .default = 1)))

# Rename columns to match calendar.txt format
calendar_data_wide <- calendar_data_wide |>
	rename_with(str_to_lower)

# Add new records to calendar
calendar <- bind_rows(calendar, calendar_data_wide)

# Fill in start_date and end_date for new records
# Uses the existing records with _R suffix to get the dates
calendar <- calendar |>
	fill(start_date, end_date, .direction = "down")

# Write updated calendar to file

write_csv(calendar, "data/gtfs_feeds/wmata/calendar.txt")
