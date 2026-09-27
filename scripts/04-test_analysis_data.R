#### Preamble ####
# Purpose: Tests the cleaned 2025 Bike Share Toronto analysis data.
# Author: Harry Zhang
# Date: 26 September 2026
# Contact: yizhiharryzhang@gmail.com
# License: MIT
# Pre-requisites: Run scripts/03-clean_data.R first.


#### Workspace setup ####
library(tidyverse)
library(arrow)
library(testthat)
library(here)

analysis_data <- open_dataset(here("data", "02-analysis_data", "trips_2025")) |>
  collect()

cleaning_log <- read_csv(
  here("data", "02-analysis_data", "cleaning_log.csv"),
  show_col_types = FALSE
)

expected_columns <- c(
  "trip_id", "start_time", "end_time", "duration_min",
  "start_station_id", "start_station_name", "end_station_id", "end_station_name",
  "bike_id", "user_type", "bike_type",
  "trip_date", "month", "day_of_week", "day_type", "start_hour", "round_trip"
)

ontario_holidays_2025 <- ymd(c(
  "2025-01-01", "2025-02-17", "2025-04-18", "2025-05-19", "2025-07-01",
  "2025-09-01", "2025-10-13", "2025-12-25", "2025-12-26"
))


#### Structure ####
test_that("the dataset has every expected column", {
  expect_setequal(names(analysis_data), expected_columns)
})

test_that("the number of trips matches the final step of the cleaning log", {
  expect_equal(nrow(analysis_data), tail(cleaning_log$trips, 1))
})

test_that("no column has missing values", {
  expect_equal(sum(is.na(analysis_data)), 0)
})

test_that("each trip appears exactly once", {
  expect_false(anyDuplicated(analysis_data$trip_id) > 0)
})


#### Categories ####
test_that("user type is only Member or Casual", {
  expect_setequal(as.character(unique(analysis_data$user_type)), c("Member", "Casual"))
})

test_that("bike type is only Classic or E-bike", {
  expect_setequal(unique(analysis_data$bike_type), c("Classic", "E-bike"))
})

test_that("day type is only Weekday or Weekend or holiday", {
  expect_setequal(unique(analysis_data$day_type), c("Weekday", "Weekend or holiday"))
})


#### Dates and times ####
test_that("every trip starts in 2025", {
  expect_true(all(year(analysis_data$start_time) == 2025))
})

test_that("month and start hour are in range and match the start time", {
  expect_true(all(analysis_data$month %in% 1:12))
  expect_true(all(analysis_data$start_hour %in% 0:23))
  expect_true(all(analysis_data$month == month(analysis_data$start_time)))
  expect_true(all(analysis_data$start_hour == hour(analysis_data$start_time)))
})

test_that("weekends and statutory holidays are classed together", {
  weekend_or_holiday <- wday(analysis_data$trip_date, week_start = 1) >= 6 |
    analysis_data$trip_date %in% ontario_holidays_2025
  expect_true(all((analysis_data$day_type == "Weekend or holiday") == weekend_or_holiday))
})

test_that("end minus start agrees with recorded duration", {
  # Clock times can differ by up to an hour across a daylight-saving change
  clock_minutes <- as.numeric(difftime(
    analysis_data$end_time, analysis_data$start_time, units = "mins"
  ))
  expect_true(all(abs(clock_minutes - analysis_data$duration_min) <= 61))
})


#### Durations ####
test_that("every trip lasts between 1 minute and 24 hours", {
  expect_true(all(analysis_data$duration_min >= 1))
  expect_true(all(analysis_data$duration_min <= 24 * 60))
})


#### Stations ####
test_that("round trips are exactly the trips that start and end at one station", {
  same_station <- analysis_data$start_station_id == analysis_data$end_station_id
  expect_true(all(analysis_data$round_trip == same_station))
})

test_that("each station ID has exactly one name", {
  station_lookup <- bind_rows(
    distinct(analysis_data, id = start_station_id, name = start_station_name),
    distinct(analysis_data, id = end_station_id, name = end_station_name)
  ) |>
    distinct()
  expect_false(anyDuplicated(station_lookup$id) > 0)
})

test_that("station names were read with the correct encoding", {
  all_names <- unique(c(analysis_data$start_station_name, analysis_data$end_station_name))
  expect_false(any(str_detect(all_names, "\uFFFD|Ã|â€")))
})

test_that("station and bike IDs are positive whole numbers", {
  expect_true(all(analysis_data$start_station_id > 0))
  expect_true(all(analysis_data$end_station_id > 0))
  expect_true(all(analysis_data$bike_id > 0))
})
