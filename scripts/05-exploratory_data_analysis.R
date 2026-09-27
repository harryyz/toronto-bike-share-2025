#### Preamble ####
# Purpose: First look at how members and casual riders differ in when, how
#   long, and how they ride, to check the paper's story before writing it up.
# Author: Harry Zhang
# Date: 26 September 2026
# Contact: yizhiharryzhang@gmail.com
# License: MIT
# Pre-requisites: Run scripts/03-clean_data.R first.


#### Workspace setup ####
library(tidyverse)
library(arrow)
library(here)

trips <- open_dataset(here("data", "02-analysis_data", "trips_2025")) |>
  collect()

peak_hours_am <- 7:9
peak_hours_pm <- 16:18


#### 1. Who rides ####
print(trips |> count(user_type) |> mutate(share = n / sum(n)))


#### 2. When: rush-hour vs midday on weekdays ####
print(
  trips |>
    filter(day_type == "Weekday") |>
    summarise(
      morning_peak = mean(start_hour %in% peak_hours_am),
      midday = mean(start_hour %in% 10:15),
      evening_peak = mean(start_hour %in% peak_hours_pm),
      .by = user_type
    )
)


#### 3. When: weekdays vs weekends, per day ####
# There are about 2.5 times as many weekdays as weekend days and holidays, so
# compare average trips per day rather than raw totals
days_by_type <- trips |>
  distinct(trip_date, day_type) |>
  count(day_type, name = "days")

print(
  trips |>
    count(user_type, day_type) |>
    left_join(days_by_type, by = "day_type") |>
    mutate(trips_per_day = n / days) |>
    select(user_type, day_type, trips_per_day) |>
    pivot_wider(names_from = day_type, values_from = trips_per_day) |>
    mutate(weekend_to_weekday_ratio = `Weekend or holiday` / Weekday)
)


#### 4. How long ####
print(
  trips |>
    summarise(
      median_min = median(duration_min),
      p25_min = quantile(duration_min, 0.25),
      p75_min = quantile(duration_min, 0.75),
      share_over_30_min = mean(duration_min > 30),
      .by = c(user_type, day_type)
    ) |>
    arrange(user_type, day_type)
)


#### 5. How: round trips and e-bikes ####
print(
  trips |>
    summarise(
      round_trip_share = mean(round_trip),
      ebike_share = mean(bike_type == "E-bike"),
      .by = user_type
    )
)


#### 6. Seasonality ####
# Each group's monthly trips relative to its own busiest month
print(
  trips |>
    count(month, user_type) |>
    pivot_wider(names_from = user_type, values_from = n) |>
    mutate(
      casual_share = Casual / (Casual + Member),
      member_vs_peak = Member / max(Member),
      casual_vs_peak = Casual / max(Casual)
    ) |>
    arrange(month),
  n = 12
)


#### 7. Do casual riders commute more in some months? ####
# Share of weekday trips starting in the morning peak, by month
print(
  trips |>
    filter(day_type == "Weekday") |>
    summarise(morning_peak = mean(start_hour %in% peak_hours_am), .by = c(month, user_type)) |>
    pivot_wider(names_from = user_type, values_from = morning_peak) |>
    arrange(month),
  n = 12
)


#### 8. Quick look: hourly pattern ####
hourly_profile <- trips |>
  count(user_type, day_type, start_hour) |>
  mutate(share = n / sum(n), .by = c(user_type, day_type))

ggplot(hourly_profile, aes(x = start_hour, y = share, colour = user_type)) +
  geom_line() +
  facet_wrap(vars(day_type)) +
  labs(x = "Hour trip started", y = "Share of the group's trips", colour = NULL) +
  theme_minimal()
