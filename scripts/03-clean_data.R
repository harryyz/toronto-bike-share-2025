#### Preamble ####
# Purpose: Cleans the raw 2025 Bike Share Toronto trip data and saves the
#   analysis dataset, along with a log of how many trips each step removed.
# Author: Harry Zhang
# Date: 26 September 2026
# Contact: yizhiharryzhang@gmail.com
# License: MIT
# Pre-requisites: Run scripts/02-download_data.R first.
# Any other information needed? The analysis data are saved as Parquet files,
#   one per month, so each file stays under GitHub's 100 MB limit.


#### Workspace setup ####
library(tidyverse)
library(arrow)
library(here)

raw_files <- list.files(
  here("data", "01-raw_data"),
  pattern = "^bikeshare_2025_\\d{2}\\.csv$",
  full.names = TRUE
)

# Ontario's nine statutory holidays in 2025. Following El-Assi et al. (2017) grouped with weekends
ontario_holidays_2025 <- ymd(c(
  "2025-01-01", # New Year's Day
  "2025-02-17", # Family Day
  "2025-04-18", # Good Friday
  "2025-05-19", # Victoria Day
  "2025-07-01", # Canada Day
  "2025-09-01", # Labour Day
  "2025-10-13", # Thanksgiving Day
  "2025-12-25", # Christmas Day
  "2025-12-26"  # Boxing Day
))


#### Read raw data ####
# The files are Windows-1252 encoded
raw_trips <- read_csv(
  raw_files,
  col_types = cols(.default = col_character()),
  locale = locale(encoding = "windows-1252")
)

cleaning_log <- tibble(step = "Raw 2025 trips", trips = nrow(raw_trips))


#### Set column names and types ####
# Timestamps are local Toronto clock times. They are parsed without a timezone
# (R labels them UTC) so daylight-saving changes cannot create missing or shifted vals
trips <- raw_trips |>
  rename_with(tolower) |>
  mutate(
    trip_id = as.integer(trip_id),
    trip_duration = as.numeric(trip_duration),
    start_station_id = as.integer(start_station_id),
    end_station_id = as.integer(end_station_id),
    bike_id = as.integer(bike_id),
    start_time = ymd_hms(start_time),
    end_time = ymd_hms(end_time)
  )

rm(raw_trips)

# Every trip must have a parsed start time
stopifnot(sum(is.na(trips$start_time)) == 0)


#### Remove invalid trips ####
# 1. Bikes that were never properly docked have no valid trip
trips <- trips |>
  filter(!is.na(start_station_id), !is.na(end_station_id), !is.na(end_time))

cleaning_log <- add_row(
  cleaning_log,
  step = "Removed trips missing a start station, end station, or end time",
  trips = nrow(trips)
)

# 2. Trips under 60 seconds are failed undocks or immediate re-docks
trips <- trips |> filter(trip_duration >= 60)

cleaning_log <- add_row(
  cleaning_log,
  step = "Removed trips shorter than 60 seconds",
  trips = nrow(trips)
)

# 3. Trips over 24 hours are system errors or unreturned bikes
trips <- trips |> filter(trip_duration <= 24 * 60 * 60)

cleaning_log <- add_row(
  cleaning_log,
  step = "Removed trips longer than 24 hours",
  trips = nrow(trips)
)


#### Rebuild station names ####
# From January to October the raw End_Station_Name repeats the start
# station's name. Names are rebuilt from station IDs instead, using each
# station's most recent name so renamed stations are labelled consistently.
station_names <- trips |>
  summarise(
    last_seen = max(start_time),
    .by = c(start_station_id, start_station_name)
  ) |>
  slice_max(last_seen, n = 1, by = start_station_id, with_ties = FALSE) |>
  select(station_id = start_station_id, station_name = start_station_name)

# Check: in November and December the raw end names are correct, so the
# rebuilt names should match them (apart from any renamed stations)
name_check <- trips |>
  filter(month(start_time) >= 11) |>
  left_join(station_names, by = c("end_station_id" = "station_id")) |>
  summarise(share_matching = mean(end_station_name == station_name, na.rm = TRUE))

print(name_check)

trips <- trips |>
  select(-start_station_name, -end_station_name) |>
  left_join(
    rename(station_names, start_station_id = station_id, start_station_name = station_name),
    by = "start_station_id"
  ) |>
  left_join(
    rename(station_names, end_station_id = station_id, end_station_name = station_name),
    by = "end_station_id"
  )

# End stations never used as a start station have no rebuilt name
print(sum(is.na(trips$end_station_name)))

# Label the few end stations that never appear as a start station
trips <- trips |>
  mutate(end_station_name = coalesce(end_station_name, paste("Station", end_station_id)))


#### Construct analysis variables ####
analysis_data <- trips |>
  mutate(
    duration_min = trip_duration / 60,
    user_type = factor(user_type, levels = c("Member", "Casual")),
    bike_type = case_when(
      bike_model == "ICONIC" ~ "Classic",
      bike_model %in% c("EFIT", "EFIT G5") ~ "E-bike"
    ),
    trip_date = as_date(start_time),
    month = month(start_time),
    day_of_week = wday(start_time, label = TRUE, week_start = 1),
    day_type = if_else(
      wday(start_time, week_start = 1) >= 6 | trip_date %in% ontario_holidays_2025,
      "Weekend or holiday",
      "Weekday"
    ),
    start_hour = hour(start_time),
    round_trip = start_station_id == end_station_id
  ) |>
  select(
    trip_id, start_time, end_time, duration_min,
    start_station_id, start_station_name, end_station_id, end_station_name,
    bike_id, user_type, bike_type,
    trip_date, month, day_of_week, day_type, start_hour, round_trip
  )


#### Save data ####
analysis_folder <- here("data", "02-analysis_data")

write_dataset(
  analysis_data,
  file.path(analysis_folder, "trips_2025"),
  format = "parquet",
  partitioning = "month",
  compression = "zstd"
)

write_csv(cleaning_log, file.path(analysis_folder, "cleaning_log.csv"))


#### Summary ####
print(cleaning_log)

saved_files <- list.files(
  file.path(analysis_folder, "trips_2025"),
  recursive = TRUE,
  full.names = TRUE
)
print(round(sum(file.size(saved_files)) / 1e6, 1))
print(round(max(file.size(saved_files)) / 1e6, 1))
