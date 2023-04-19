# Run this script to get your project folder set up.
library(fs)
library(here)

fs::dir_create('sensitive')

fs::file_create(here::here('sensitive', 'test.txt'))