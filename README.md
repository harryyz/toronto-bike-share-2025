# Casual Riders on Bike Share Toronto Are Not All Leisure Riders

## Overview

This repository contains the data, code, and paper for an analysis of 7.8 million Bike Share Toronto trips from 2025. It compares members and casual riders on when trips start, how long they last, and how these patterns change across the year. Casual trips look like leisure riding overall, but in winter casual riders' weekday trips look much more like members', suggesting the "casual" label covers more than one kind of rider.

The data are the Bike Share Toronto Ridership Data, published by the Toronto Parking Authority on the City of Toronto Open Data Portal.

## File structure

The repo is structured as:

- `data/00-simulated_data` contains the simulated dataset used to plan the analysis and tests.
- `data/01-raw_data` holds the raw 2025 ridership files as downloaded from Open Data Toronto. These files are too large for GitHub and are not included; running `scripts/02-download_data.R` recreates them.
- `data/02-analysis_data` contains the cleaned analysis data (Parquet files, one per month) and `cleaning_log.csv`, which records how many trips each cleaning step removed.
- `other/literature` contains the academic papers cited in the paper.
- `other/llm_usage` contains `usage.txt`, the full history of chats with an LLM.
- `other/sketches` contains sketches of the dataset, summary table, and planned figures.
- `paper` contains the Quarto document, the bibliography files, and the PDF of the paper.
- `scripts` contains the R scripts used to simulate, test, download, clean, and explore the data.

## Reproducing the analysis

1. Open `toronto_bike_share.Rproj` in RStudio.
2. Install the packages used: `tidyverse`, `opendatatoronto`, `ckanr`, `arrow`, `testthat`, `here`, `tinytable`, and `knitr`.
3. Run the scripts in order:
   - `00-simulate_data.R` and `01-test_simulated_data.R`
   - `02-download_data.R` (downloads about 1 GB of raw data)
   - `03-clean_data.R` and `04-test_analysis_data.R`
   - `05-exploratory_data_analysis.R` (optional)
4. Render `paper/paper.qmd` to PDF.

## Statement on LLM usage

Used Claude (Anthropic) Opus 5.5.
Claude wrote most of the R code (simulation, tests, download, cleaning, figures, and tables).
Claude helped choose and refine the final research question, and produced a detailed recommended outline for the paper. I agreed with and used the general section numbering on this outline.
Claude helped identify related literature, I read all of the recommended literature and selected ones I found useful for the paper. I also personally found related literature and discussed with claude on the viability, which was also used and cited.
At no point did I ever copy/paste any of claude's prose, but I used ideas of how to arrange information across each section from the outline, specifically especially in 2.3, 2.4, and 2.6. The last version of the outline I referenced is in other/llm_usage/outline.md.
After writing, I asked claude whether each section follows the rubric, and enacted changes on my own.
Full history in other/llm_usage/usage.txt

P.S. Claude also helped write this README. The Statement on LLM usage is written by me.
