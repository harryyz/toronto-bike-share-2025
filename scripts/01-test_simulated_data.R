#### Preamble ####
# Purpose: Tests the simulated Bike Share Toronto data: that it is valid, and
#   that it contains the patterns the simulation was designed to produce.
# Author: Harry Zhang
# Date: 26 September 2026
# Contact: yizhiharryzhang@gmail.com
# License: MIT
# Pre-requisites: Run scripts/00-simulate_data.R first.


#### Workspace setup ####
library(tidyverse)
library(testthat)
library(here)

simulated_data <- read_csv(
  here("data", "00-simulated_data", "simulated_trips.csv"),
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
test_that("the dataset has 10,000 trips and every expected column", {
  expect_equal(nrow(simulated_data), 10000)
  expect_setequal(names(simulated_data), expected_columns)
})

test_that("no column has missing values", {
  expect_equal(sum(is.na(simulated_data)), 0)
})

test_that("each trip appears exactly once", {
  expect_false(anyDuplicated(simulated_data$trip_id) > 0)
})


#### Categories ####
test_that("categorical variables contain only expected values", {
  expect_setequal(unique(simulated_data$user_type), c("Member", "Casual"))
  expect_setequal(unique(simulated_data$bike_type), c("Classic", "E-bike"))
  expect_setequal(unique(simulated_data$day_type), c("Weekday", "Weekend or holiday"))
})


#### Dates and times ####
test_that("every trip starts in 2025, with month and hour matching the start time", {
  expect_true(all(year(simulated_data$start_time) == 2025))
  expect_true(all(simulated_data$month == month(simulated_data$start_time)))
  expect_true(all(simulated_data$start_hour == hour(simulated_data$start_time)))
})

test_that("weekends and statutory holidays are classed together", {
  weekend_or_holiday <- wday(simulated_data$trip_date, week_start = 1) >= 6 |
    simulated_data$trip_date %in% ontario_holidays_2025
  expect_true(all((simulated_data$day_type == "Weekend or holiday") == weekend_or_holiday))
})

test_that("end minus start equals the recorded duration", {
  clock_minutes <- as.numeric(difftime(
    simulated_data$end_time, simulated_data$start_time, units = "mins"
  ))
  expect_true(all(abs(clock_minutes - simulated_data$duration_min) < 0.02))
})


#### Durations and stations ####
test_that("every trip lasts between 1 minute and 24 hours", {
  expect_true(all(between(simulated_data$duration_min, 1, 24 * 60)))
})

test_that("round trips are exactly the trips that start and end at one station", {
  same_station <- simulated_data$start_station_id == simulated_data$end_station_id
  expect_true(all(simulated_data$round_trip == same_station))
})

test_that("station IDs are within the simulated range", {
  expect_true(all(between(simulated_data$start_station_id, 7000, 7049)))
  expect_true(all(between(simulated_data$end_station_id, 7000, 7049)))
})


#### Designed patterns ####
# These check that the simulation contains the relationships it was built
# to have, which the real data are later compared against.
casual_share_by_season <- simulated_data |>
  mutate(season = case_when(
    month %in% c(7, 8) ~ "Summer",
    month %in% c(1, 2) ~ "Winter"
  )) |>
  filter(!is.na(season)) |>
  summarise(casual_share = mean(user_type == "Casual"), .by = season)

by_user_type <- simulated_data |>
  summarise(
    weekend_share = mean(day_type == "Weekend or holiday"),
    morning_peak_share = mean(start_hour[day_type == "Weekday"] %in% 7:9),
    median_duration = median(duration_min),
    round_trip_share = mean(round_trip),
    .by = user_type
  )

member <- filter(by_user_type, user_type == "Member")
casual <- filter(by_user_type, user_type == "Casual")

test_that("casual riders make up a larger share of trips in summer than winter", {
  expect_gt(
    casual_share_by_season$casual_share[casual_share_by_season$season == "Summer"],
    casual_share_by_season$casual_share[casual_share_by_season$season == "Winter"]
  )
})

test_that("casual riders ride on weekends more than members do", {
  expect_gt(casual$weekend_share, member$weekend_share)
})

test_that("members ride in the weekday morning peak more than casual riders", {
  expect_gt(member$morning_peak_share, casual$morning_peak_share)
})

test_that("casual trips are longer and more often round trips", {
  expect_gt(casual$median_duration, member$median_duration)
  expect_gt(casual$round_trip_share, member$round_trip_share)
})
