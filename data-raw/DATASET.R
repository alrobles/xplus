## code to prepare `DATASET` dataset goes here
getwd()
lacs <- readr::read_csv("data-raw/lacs.csv")
dplyr::count(lacs, class)
usethis::use_data(lacs, overwrite = TRUE)



library(dplyr)
lacsSample <- dplyr::sample_n(lacs, 600)

usethis::use_data(lacsSample, overwrite = TRUE)
