Choosing replications
================
Amy Heather
2025-03-06

- [Set up](#set-up)
- [Choosing the number of
  replications](#choosing-the-number-of-replications)
- [Run time](#run-time)

This notebook documents the choice of the number of replications.

The generated images are saved and then loaded, so that we view the
image as saved (i.e. with the dimensions set in `ggsave()`). This also
avoids the creation of a `_files/` directory when knitting the document
(which would save all previewed images into that folder also, so they
can be rendered and displayed within the output `.md` file, even if we
had not specifically saved them). These are viewed using
`include_graphics()`, which must be the last command in the cell (or
last in the plotting function).

The run time is provided at the end of the notebook.

## Set up

Install the latest version of the local simulation package.

``` r
devtools::load_all()
```

    ## ℹ Loading simulation

Load required packages.

``` r
# nolint start: undesirable_function_linter.
library(data.table)
library(dplyr)
```

    ## 
    ## Attaching package: 'dplyr'

    ## The following objects are masked from 'package:data.table':
    ## 
    ##     between, first, last

    ## The following object is masked from 'package:testthat':
    ## 
    ##     matches

    ## The following objects are masked from 'package:stats':
    ## 
    ##     filter, lag

    ## The following objects are masked from 'package:base':
    ## 
    ##     intersect, setdiff, setequal, union

``` r
library(knitr)
library(simulation)
library(tidyr)
```

    ## 
    ## Attaching package: 'tidyr'

    ## The following object is masked from 'package:testthat':
    ## 
    ##     matches

``` r
options(data.table.summarise.inform = FALSE)
options(dplyr.summarise.inform = FALSE)
# nolint end
```

Start timer.

``` r
start_time <- Sys.time()
```

Define path to outputs folder.

``` r
output_dir <- file.path("..", "outputs")
```

## Choosing the number of replications

The **confidence interval method** can be used to select the number of
replications to run. The more replications you run, the narrower your
confidence interval becomes, leading to a more precise estimate of the
model’s mean performance.

First, you select a desired confidence interval - for example, 95%.
Then, run the model with an increasing number of replications, and
identify the number required to achieve that precision in the estimate
of a given metric - and also, to maintain that precision (as the
intervals may converge or expand again later on).

This method is less useful for values very close to zero - so, for
example, when using utilisation (which ranges from 0 to 1) it is
recommended to multiple values by 100.

When selecting the number of replications you should repeat the analysis
for all performance measures and select the highest value as your number
of replications.

It’s important to check ahead, to check that the 5% precision is
maintained - which is fine in this case - it doesn’t go back up to
future deviation.

``` r
path <- file.path(output_dir, "choose_param_conf_int_1.png")

# Run calculations and produce plot
ci_df <- confidence_interval_method(
  replications = 150L,
  desired_precision = 0.05,
  metric = "mean_activity_time_nurse",
  yaxis_title = "Mean time with nurse",
  path = path,
  min_rep = 98L
)
```

    ## Reached desired precision (0.05) in 98 replications.

``` r
# Preview dataframe
head(ci_df)
```

    ##   replications cumulative_mean cumulative_std ci_lower  ci_upper perc_deviation
    ## 1            1       10.740547             NA       NA        NA             NA
    ## 2            2        8.920561             NA       NA        NA             NA
    ## 3            3        8.242866       2.165677 2.863026 13.622707       65.26662
    ## 4            4        8.504535       1.844086 5.570182 11.438888       34.50339
    ## 5            5        7.760938       2.305467 4.898323 10.623553       36.88491
    ## 6            6        7.820313       2.067195 5.650925  9.989701       27.74042

``` r
# View first ten rows were percentage deviation is below 5
ci_df %>%
  filter(perc_deviation < 5L) %>%
  head(10L)
```

    ##    replications cumulative_mean cumulative_std ci_lower ci_upper perc_deviation
    ## 1            98        8.461235       2.106669 8.038875 8.883596       4.991712
    ## 2            99        8.475054       2.100398 8.056137 8.893971       4.942943
    ## 3           100        8.468351       2.090838 8.053483 8.883219       4.899036
    ## 4           101        8.473309       2.080954 8.062503 8.884115       4.848241
    ## 5           102        8.478815       2.071373 8.071959 8.885671       4.798504
    ## 6           103        8.485316       2.062250 8.082270 8.888361       4.749915
    ## 7           104        8.490698       2.052949 8.091450 8.889945       4.702173
    ## 8           105        8.477837       2.047301 8.081634 8.874040       4.673399
    ## 9           106        8.456515       2.049320 8.061841 8.851190       4.667105
    ## 10          107        8.459470       2.039859 8.068501 8.850440       4.621677

``` r
# View plot
include_graphics(path)
```

![](../outputs/choose_param_conf_int_1.png)<!-- -->

It is also important to check across multiple metrics.

``` r
path <- file.path(output_dir, "choose_param_conf_int_3.png")

# Run calculations and produce plot
ci_df <- confidence_interval_method(
  replications = 200L,
  desired_precision = 0.05,
  metric = "utilisation_nurse",
  yaxis_title = "Mean nurse utilisation",
  path = path,
  min_rep = 148L
)
```

    ## Reached desired precision (0.05) in 148 replications.

``` r
# View first ten rows were percentage deviation is below 5
ci_df %>%
  filter(perc_deviation < 5L) %>%
  head(10L)
```

    ##    replications cumulative_mean cumulative_std ci_lower ci_upper perc_deviation
    ## 1           148        45.73420       14.04814 43.45214 48.01625       4.989822
    ## 2           149        45.89021       14.12952 43.60278 48.17764       4.984574
    ## 3           150        45.90075       14.08261 43.62865 48.17286       4.950028
    ## 4           151        45.84563       14.05193 43.58612 48.10513       4.928512
    ## 5           152        45.92331       14.03803 43.67359 48.17302       4.898849
    ## 6           153        45.84086       14.02890 43.60008 48.08163       4.888154
    ## 7           154        45.71614       14.06836 43.47650 47.95579       4.899034
    ## 8           155        45.85137       14.12331 43.61035 48.09239       4.887567
    ## 9           156        45.87804       14.08162 43.65092 48.10515       4.854423
    ## 10          157        46.12548       14.37477 43.85937 48.39160       4.912928

``` r
# View plot
include_graphics(path)
```

![](../outputs/choose_param_conf_int_3.png)<!-- -->

## Run time

``` r
# Get run time in seconds
end_time <- Sys.time()
runtime <- as.numeric(end_time - start_time, units = "secs")

# Display converted to minutes and seconds
minutes <- as.integer(runtime / 60L)
seconds <- as.integer(runtime %% 60L)
cat(sprintf("Notebook run time: %dm %ds", minutes, seconds))
```

    ## Notebook run time: 0m 9s
