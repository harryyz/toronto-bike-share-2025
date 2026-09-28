# Paper outline

Working notes for writing the paper. Facts, numbers, and citations to turn into prose.
Items marked **[check]** need confirming before they go in the paper.

---

## Paper framing (for reference)
- Research question: in 2025, do Bike Share Toronto's casual riders still ride like leisure users, or has casual riding become more commuter-like?
- Main theme: how members and casual riders differ in when, how long, and how they ride
- Headline finding: "casual" is not one group; winter casual riders ride more like members, while the summer surge looks like leisure
- Supporting threads: pricing shapes trip length; e-bike use
- Why the label matters: "Casual" is defined by what riders pay, and that category widened in 2023, so it can't be assumed to mean "tourist". This is the motivation for the question, not a separate theme

## 1. Introduction notes (to expand later)
- Buck et al. define casual riders by product (short-term passes vs annual or monthly membership); their survey found most short-term users in Washington, DC were visitors (66%) riding for tourism (53%) [@buck2013]. This is where the "casual = tourist" assumption comes from. Caveat: surveyed at five downtown stations chosen for heavy short-term use
- El-Assi et al. found casual riders split evenly between weekdays and weekends in Toronto in 2013 [@elassi2017]

## 2. Data

### 2.1 Source and context

**What the dataset is**
- Bike Share Toronto Ridership Data, published by the Toronto Parking Authority (TPA) on the City of Toronto Open Data Portal [@bikesharedata]
- Accessed through `opendatatoronto` [@R-opendatatoronto]; cite the dataset and the package separately
- Published as one zip file per year of monthly CSV files; refreshed monthly
- This paper uses all of 2025: 12 monthly files, 7,812,520 trips before cleaning, 7,788,842 after
- One row per trip. Recorded fields: trip ID, duration, start and end station (ID and name), start and end time, bike ID, user type, bike model
- Licence: Open Government Licence – Toronto

**Why the data exist (who collects it and for what)**
- Collected automatically by the bike share system as part of operating it and charging riders, not for research
- TPA runs the system; it is a self-funding City agency, and parking revenue funds bike share expansion [@tpa2023rates]
- The system has grown from 80 stations and about 400,000 rides in 2011 to 780+ stations, 8,800 bikes (1,825 e-bikes) and a projected 5.5 million rides in 2023 [@tpa2023rates]
- Worth noting: our 2025 data has 7.8 million trips, so ridership kept growing after 2023

**Broader context: why 2025 is a useful year**
- New rate structure launched April 3, 2023, the first change since 2017 [@tpa2023rates]
- Casual prices described at the 2023 launch [@cycleto2023pricing; @tpa2023rates] match the current pricing page [@bikesharepricing], suggesting casual pricing was broadly stable over 2025. Don't claim prices were unchanged throughout; the sources only show both ends
- Membership trip limits (30 or 45 min) and the day pass's 90-minute limit: attribute to *current* pricing only
- E-bikes now a large share of the fleet and of trips (19.4% of 2025 trips)
- Bill 212 context: province passed a law in 2024 to remove bike lanes on Bloor Street, Yonge Street and University Avenue; a lower court blocked removal in July 2025; the Court of Appeal reversed that on August 14, 2026 [@cbc2026appeal]. 2025 is therefore a snapshot before any removal. Say plainly that this paper does not measure the effect of bike lanes

**Ethical considerations**
- Anonymized: no rider names or account IDs; riders cannot be linked across trips
- Trade-off to mention: this protects privacy but means we can only study *trips*, not *people* (links to limitations)
- Residual privacy risk: exact start and end times plus stations could, in principle, help identify someone who rides the same route regularly. The data publisher's choice to omit rider IDs reduces this
- Coverage and equity: stations are concentrated downtown; the TPA is expanding into Neighbourhood Improvement Areas (211 of 375 new stations in 2024) [@tpa2023rates]. So the data describe people with good access to stations, not all Torontonians
- Pricing shapes who appears in the data and as what (member vs casual)

**Statistical considerations**
- A census of every trip in 2025, not a sample, so there is no sampling error in the counts
- But the population is trips, not riders. Frequent riders contribute many trips, so patterns are weighted toward heavy users (e.g. a commuter riding 400 times counts 400 times; a tourist riding once counts once)
- Not all cycling in Toronto: excludes people riding their own bikes, so it says nothing about cycling overall

**Similar datasets considered, and why not used**
- Earlier years of the same dataset (2014–2024): formats change across years (2016 change of software provider noted by the publisher; quarterly files until 2019, monthly after), and years before April 2023 had different prices. 2025 is the most recent complete year under current prices
- 2026 data: available only up to part of the year, so seasonality can't be compared across a full year
- "Bike Share Toronto" real-time dataset on Open Data Toronto (TPA; GBFS JSON feeds): gives current station locations and live bike/dock availability, not individual trips, and keeps no history. A public request to track historical station locations was put in the Open Data team's backlog in November 2025. Could supply station coordinates if a map were added. Don't quote its description's system size (6,850 bikes, 625 stations): it's older than the TPA's 2023 figures
- City of Toronto bicycle counts / cycling network datasets: count cyclists or describe infrastructure, but don't distinguish bike share riders or rider type **[check exact dataset names on the portal]**
- Surveys (e.g. Census commuting questions, the Transportation Tomorrow Survey): record trip purpose and demographics, which this dataset lacks, but only cover commuting or a sample of households, and are collected infrequently
- Optional: El-Assi et al. used 2013 data provided directly by the operator [@elassi2017]; ours is the public release

---

### 2.2 Measurement: from a bike ride to a row in the dataset

**Suggested shape: four paragraphs**
1. From ride to record, and what isn't measured
2. What the "Casual" label covers, and why it motivates the research question
3. How pricing shapes trip length
4. Recording problems (brief, point to @sec-appendix-cleaning) and how to read round trips and weekends

**The chain from event to record**
1. A rider unlocks a bike at a station using a membership, a day pass, or pay-as-you-go payment
2. The system records the trip ID, start time, start station and bike ID at undocking
3. The rider returns the bike to any station's dock; the system records the end time and end station
4. Duration = time between undocking and docking, recorded in seconds
5. Each trip is labelled "Member" or "Casual" according to the rider's account or payment; what these labels cover is discussed below (don't define them as fact here)
6. Bike model comes from which bike was used: ICONIC (classic) or EFIT / EFIT G5 (e-bikes)

**What is NOT measured (worth stating clearly)**
- Route taken or distance travelled: only start and end stations
- Trip purpose: commuting vs leisure must be inferred from timing, duration and round trips. Everything the paper says about "commuting" is an interpretation of patterns, not a recorded fact
- Who the rider is: no demographics, and no rider ID
- Weather

**What the "Casual" label actually covers**
- Documented definition: the publisher's readme defines members as "annual pass holders" and casual users as "24 or 72 hour pass holders" [@bikesharedata]
- But the readme covers only the 2014–2016 files; no definition is given for later years (state this as fact)
- Since then the products have changed: the 72-hour pass was dropped and single rides became pay-as-you-go, priced per minute, in the 2023 rate change [@tpa2023rates; @cycleto2023pricing]
- Current non-membership products: pay-as-you-go ($1 to unlock + $0.12/min classic, $0.20/min e-bike) and the Day Pass ($15, unlimited 90-minute classic rides; e-bikes charged per minute) [@bikesharepricing]
- Inference (word it as one): in 2025, "Casual" most likely covers both day-pass holders and pay-as-you-go riders, since these are the only non-membership products the operator offers
- Evidence that "Member" still means membership holders: only 4.5% of member trips exceed 30 minutes and 0.9% exceed 45 minutes, the trip lengths included in the two membership plans, compared with 22.7% and 13.7% of casual trips (over 90 minutes: 0.14% vs 3.5%)
- Consequence: the data record only "Casual", not which product was used (day pass or pay-as-you-go) and nothing about the rider (resident or visitor). Every combination is possible and all look the same in the data
- So the paper can't sort casual riders into types. It can only see how casual trips are used: when they start, how long they last, whether they return to the starting station, and how this changes by season. The question is whether those trips look like leisure or commuting
- Buck et al.'s definition and survey: leave out of 2.2; use in the introduction instead (see Introduction notes)

**How pricing shapes what we measure**
- Attribute these limits to *current* pricing ("Under current pricing, ...") since the sources only confirm prices at the 2023 launch and today
- Annual memberships (Annual 30, $105; Annual 45, $120) include unlimited 30- or 45-minute classic trips; longer trips cost extra, so members have a reason to keep trips short [@bikesharepricing]
- The data fit this: member trips drop from 4.5% over 30 minutes to 0.9% over 45 minutes (use the numbers here or in the Casual paragraph, not both)
- Day pass holders get unlimited 90-minute classic rides, making long leisure trips cheap
- Pay-as-you-go riders pay by the minute; e-bikes cost extra for everyone
- So differences in trip length reflect pricing as well as trip purpose

**Recording problems found in the data (keep to one or two sentences here; full details go in @sec-appendix-cleaning)**
- End-station names wrong from January to October 2025: the raw end-station name repeated the start station's name, although end-station IDs were correct. The publisher fixed this from November. Names were rebuilt from station IDs; the rebuilt names matched the correct November–December names 100%
- Very short trips: 16,709 trips under 60 seconds, likely failed unlocks or immediately re-docking a faulty bike. Removed (El-Assi et al. used a 30-second cutoff for the same reason [@elassi2017])
- Incomplete trips: 6,957 trips missing an end station, end time or start station, likely bikes not properly docked, lost or stolen. Removed
- Very long trips: 12 trips over 24 hours, likely system errors or unreturned bikes. Removed
- Four stations renamed during the year: each station labelled with its most recent name
- 20 trips ended at stations never used as a starting point in 2025, so no name could be rebuilt; these stations are labelled by ID
- In total 23,678 trips removed (0.3%), so cleaning barely changes the picture

**Things to keep in mind when interpreting**
- Station-to-station "round trips" (same start and end station) are a sign of leisure riding, but could also include some bike swaps
- Weekday vs weekend: weekends and Ontario's nine statutory holidays grouped together, following El-Assi et al. [@elassi2017]
- Times are local Toronto clock times

**Table 1: variable dictionary**
- Code chunk `tbl-variables` (given in chat); place it at the start of 2.2 or the end of 2.1, and refer to it as @tbl-variables
- Plain-language names, not code names; replace the example station name with one that exists in the data

---

### 2.3 Rider type and season (@fig-monthly)

**Introduce the figure**
- Rider type and month are the first two variables: @fig-monthly shows every 2025 trip by month, split into member and casual trips
- Bars count every trip, so they add up to the full 7,788,842

**Overall split**
- Members made 5,654,702 trips (72.6%); casual riders 2,134,140 (27.4%)

**Both groups ride more in summer**
- Total trips rise from 125,670 in February (the lowest month) to about 1.19 million in July (the highest), roughly nine times as many
- Toronto's system runs all year, unlike many North American systems [@elassi2017]

**But casual riding is far more seasonal**
- Members: from 115,773 trips in February to 783,546 in July, about 7 times as many. Even in the quietest months, members still make 15–25% of their peak-month trips (February 15%, January 24%, December 25%)
- Casual: from 9,204 trips in February to 411,829 in August, about 45 times as many. In winter, casual trips fall to 2–6% of their August peak (February 2%, January 4%, December 6%)
- Casual share of all trips: about 7–8% in January and February, above 30% from June to September, peaking at 35% in August

**Interpretation (hedged)**
- Fits the idea of casual riding as fair-weather or leisure riding: cold and rain reduce bikeshare use and trip length [@gebhart2014], and bad weather affects casual users more than members [@fishman2016]
- Members' steadier riding fits regular, year-round use such as commuting
- The data contain no weather, so linking the pattern to weather is an interpretation (as noted in @sec-data-measurement)

**Caveat**
- Trips, not riders: fewer casual trips in winter could mean fewer casual riders, or the same riders riding less. The data can't tell these apart

**Lead into later figures**
- Winter casual riding is small but not zero (about 9,000–23,000 trips a month). The question for @fig-casual-season: do these winter casual trips look different from summer's?

**Figure check**
- Caption numbers match the data: February 9,204 ("about 9,000"), August 411,829 ("over 400,000"), 7.4% and 35.4% ("7% to 35%")

---

### 2.4 When trips start (@fig-hour)

**Introduce the figure and the variables**
- Start hour (0 to 23) and day type; each line shows the share of a group's trips starting in each hour, so members and casual riders can be compared despite their different totals
- Day type groups weekends with Ontario's nine statutory holidays, following @elassi2017 (mention the grouping here, where it first matters)

**Weekdays: members ride at both rush hours**
- Two sharp member peaks: around 8 am and 5 pm
- 19.4% of members' weekday trips start between 7 and 10 am, compared with 10.8% of casual trips
- This two-peak weekday shape matches what @bean2021 found across 40 cities and read as commuting

**Weekdays: casual riders share only the evening peak**
- Between 4 and 7 pm the groups are almost identical: 29.6% of member trips vs 30.2% of casual trips
- Midday (10 am to 4 pm) is slightly more important for casual riders: 28.9% vs 26.1%
- Interpretation (hedged, give possibilities, not a conclusion): one-way evening trips could be people riding home after taking transit in, or after-work outings. The data can't tell which

**Weekends and holidays: both groups look alike**
- One broad afternoon peak for both, highest around 3 to 4 pm, with casual riders slightly later
- @bean2021 found weekend use peaks around 2 to 3 pm in most systems; Toronto's is similar, slightly later
- Worth one sentence: on weekends, member and casual riding is hard to tell apart

**How much each group rides on weekends (trips per day, from the exploratory analysis)**
- Members: 16,695 trips per weekday vs 12,811 per weekend day or holiday (weekend days about 0.77 times as busy)
- Casual riders: 5,130 per weekday vs 7,446 per weekend day or holiday (about 1.45 times as busy)
- Explain briefly why per day: there are about 2.5 times as many weekdays as weekend days and holidays, so raw totals would make everyone look like a weekday rider
- Comparison with 2013: @elassi2017 found members made 60.5% of their trips on weekdays, while casual riders were split about evenly. Their measure differs from trips per day, so compare the direction, not the numbers **[optional: compute each group's weekday share of trips for a like-for-like comparison]**

**Figure check**
- Caption numbers match the exploratory output (19.4% vs 10.8%; 29.6% vs 30.2%)
