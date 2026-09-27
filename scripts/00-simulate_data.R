#### Preamble ####
# Purpose: Simulates a year of Bike Share Toronto trips with the same
#   structure as the cleaned analysis data, so the analysis and tests can be
#   planned before the real data are used.
# Author: Harry Zhang
# Date: 26 September 2026
# Contact: yizhiharryzhang@gmail.com
# License: MIT
# Pre-requisites: The tidyverse and here packages are installed.
# Any other information needed? The simulated patterns reflect expectations
#   from the literature (members commute, casual riders ride for leisure and
#   mostly in summer), not results from the real data.


#### Workspace setup ####
library(tidyverse)
library(here)

set.seed(853)

n_trips <- 10000
station_ids <- 7000:7049

ontario_holidays_2025 <- ymd(c(
  "2025-01-01", "2025-02-17", "2025-04-18", "2025-05-19", "2025-07-01",
  "2025-09-01", "2025-10-13", "2025-12-25", "2025-12-26"
))


#### Simulate the calendar ####
# Riding peaks in late July and is lowest in late January. `season` runs from
# 0 (midwinter) to 1 (midsummer) and sets how busy each day is.
calendar_2025 <- tibble(
  trip_date = seq(ymd("2025-01-01"), ymd("2025-12-31"), by = "day")
) |>
  mutate(
    day_type = if_else(
      wday(trip_date, week_start = 1) >= 6 | trip_date %in% ontario_holidays_2025,
      "Weekend or holiday",
      "Weekday"
    ),
    season = (1 + cos(2 * pi * (yday(trip_date) - 205) / 365)) / 2,
    day_weight = 0.1 + season
  )


#### Helper: start hour ####
# Weekday members often ride at the morning and evening rush hours. Casual
# riders rarely ride in the morning rush. Weekend trips peak mid-afternoon.
simulate_start_hour <- function(user_type, day_type) {
  n <- length(user_type)
  casual <- user_type == "Casual"
  weekday <- day_type == "Weekday"
  p_morning <- if_else(casual, 0.08, 0.20)
  p_evening <- 0.30
  draw <- runif(n)

  hour <- case_when(
    weekday & draw < p_morning ~ rnorm(n, mean = 8, sd = 0.8),
    weekday & draw < p_morning + p_evening ~ rnorm(n, mean = 17, sd = 1),
    weekday ~ runif(n, min = 6, max = 24),
    .default = rnorm(n, mean = 14.5, sd = 3.5)
  )

  pmin(pmax(floor(hour), 0), 23)
}


#### Simulate trips ####
simulated_data <- calendar_2025 |>
  slice_sample(n = n_trips, weight_by = day_weight, replace = TRUE) |>
  mutate(
    # Casual riding is more likely in summer and on weekends
    p_casual = plogis(-2.6 + 1.6 * season + 0.9 * (day_type == "Weekend or holiday")),
    user_type = if_else(runif(n()) < p_casual, "Casual", "Member"),
    casual = user_type == "Casual",
    weekend = day_type == "Weekend or holiday",

    # When the trip starts
    start_hour = simulate_start_hour(user_type, day_type),
    start_time = as_datetime(trip_date) + hours(start_hour) +
      seconds(sample(0:3599, n(), replace = TRUE)),

    # How long it lasts: casual trips are longer and more variable,
    # especially on weekends
    median_min = case_when(
      casual & weekend ~ 17,
      casual ~ 13.5,
      weekend ~ 10.5,
      .default = 10
    ),
    duration_min = rlnorm(n(), meanlog = log(median_min), sdlog = if_else(casual, 0.8, 0.6)),
    duration_min = round(pmin(pmax(duration_min, 1), 24 * 60) * 60) / 60,
    end_time = start_time + seconds(duration_min * 60),

    # Casual riders use e-bikes and make round trips more often
    bike_type = if_else(runif(n()) < if_else(casual, 0.24, 0.18), "E-bike", "Classic"),
    round_trip = runif(n()) < if_else(casual, 0.07, 0.015),

    # Stations: a round trip ends where it started; any other trip ends at a
    # different station
    start_station_id = sample(station_ids, n(), replace = TRUE),
    end_station_id = if_else(
      round_trip,
      start_station_id,
      min(station_ids) +
        (start_station_id - min(station_ids) + sample(1:49, n(), replace = TRUE)) %%
          length(station_ids)
    ),
    start_station_name = paste("Station", start_station_id),
    end_station_name = paste("Station", end_station_id),

    bike_id = sample(1:8000, n(), replace = TRUE),
    month = month(trip_date),
    day_of_week = wday(trip_date, label = TRUE, week_start = 1)
  ) |>
  arrange(start_time) |>
  mutate(trip_id = row_number()) |>
  select(
    trip_id, start_time, end_time, duration_min,
    start_station_id, start_station_name, end_station_id, end_station_name,
    bike_id, user_type, bike_type,
    trip_date, month, day_of_week, day_type, start_hour, round_trip
  )


#### Save data ####
write_csv(simulated_data, here("data", "00-simulated_data", "simulated_trips.csv"))
