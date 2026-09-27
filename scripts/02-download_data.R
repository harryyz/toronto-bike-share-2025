#### Preamble ####
# Purpose: Downloads the 2025 Bike Share Toronto ridership data from the City
#   of Toronto Open Data Portal and saves the unedited monthly files.
# Author: Harry Zhang
# Date: 26 September 2026
# Contact: yizhiharryzhang@gmail.com
# License: MIT
# Pre-requisites: The opendatatoronto, ckanr, and here packages are installed.
# Any other information needed? The raw files are large and are excluded from
#   version control (see .gitignore). Running this script recreates them.


#### Workspace setup ####
library(opendatatoronto)
library(here)

# The 2025 file is very large... so wait.
options(timeout = 1200)

raw_data_folder <- here("data", "01-raw_data")
dir.create(raw_data_folder, showWarnings = FALSE, recursive = TRUE)


#### Find the 2025 resource ####
# Use opendatatoronto to look up the dataset's resources, then select 2025
resources <- list_package_resources("bike-share-toronto-ridership-data")
resource_2025 <- resources[resources$name == "bikeshare-ridership-2025.zip", ]

stopifnot(nrow(resource_2025) == 1)

# Look up the resource's download link on the portal's CKAN server
resource_info <- ckanr::resource_show(
  id = resource_2025$id,
  url = "https://ckan0.cf.opendata.inter.prod-toronto.ca/"
)


#### Download and unzip ####
zip_path <- file.path(raw_data_folder, "bikeshare_ridership_2025.zip")

download.file(resource_info$url, destfile = zip_path, mode = "wb")

unzip(zip_path, exdir = raw_data_folder)


#### Check what was downloaded ####
raw_files <- list.files(raw_data_folder, recursive = TRUE, full.names = TRUE)

print(data.frame(
  file = basename(raw_files),
  size_mb = round(file.size(raw_files) / 1e6, 1)
))
