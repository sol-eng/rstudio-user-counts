# Quick checks to verify MAU count scripts
library(tidyverse)

# RSP ----
log_path <- "<LOG_PATH>"
read_csv(log_path) %>% 
  mutate(timestamp = lubridate::as_datetime(timestamp / 1000),
         month = format(timestamp, "%m-%Y")) %>% 
  filter(type %in% c("auth_login", "session_start")) %>% 
  select(username, month) %>% 
  unique() %>% 
  count(month)
