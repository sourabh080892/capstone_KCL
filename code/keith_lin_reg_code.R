library(tidyverse)
library(here)
library(readxl)
library(janitor)

# LOAD IN DATA

# Data for SU Part 1 - Filed Cases and Hearings
D11_filed_cases <- read_excel(here::here("data", "raw", "Data for SU Part 1 - Filed Cases and Hearings.xlsx"), sheet = "FiledCases SU") %>% clean_names()
D12_case_event <- read_excel(here::here("data", "raw", "Data for SU Part 1 - Filed Cases and Hearings.xlsx"), sheet = "CaseEvents SU") %>% clean_names()
D13_case_event_key <- read_excel(here::here("data", "raw", "Data for SU Part 1 - Filed Cases and Hearings.xlsx"), sheet = "CaseEvent Key") %>% clean_names()
D14_case_type <- read_excel(here::here("data", "raw", "Data for SU Part 1 - Filed Cases and Hearings.xlsx"), sheet = "CaseType Key") %>% clean_names()

# Data for SU Part 2
D21_charge <- read_excel(here::here("data", "raw", "Data for SU Part 2.xlsx"), sheet = "SU Charges") %>% clean_names()
D22_charge_def <- read_excel(here::here("data", "raw", "Data for SU Part 2.xlsx"), sheet = "Charge Definitions") %>% clean_names()
D23_dispo_key <- read_excel(here::here("data", "raw", "Data for SU Part 2.xlsx"), sheet = "Disposition Key") %>% clean_names()
D24_crime_hist <- read_excel(here::here("data", "raw", "Data for SU Part 2.xlsx"), sheet = "SU CrimHist") %>% clean_names()

# Data for SU Part 3 - custody history
D31_custody_hist <- read_excel(here::here("data", "raw", "Data for SU Part 3 - custody history.xlsx"), sheet = "CustodyHistory SU") %>% clean_names()

# treated events_with_missing_status
events_with_missing_def_status <- read_csv(here::here("data", "processed", "events_with_missing_def_status.csv"))
dfa_by_category <- read_csv(here::here("data", "processed", "dfa_by_category_eda.csv"))

revised_D13_case_event_key <- read_excel(here::here("data", "raw", "Cleaned Criminal Hist.xlsx"), sheet = "CaseEvent Key") %>% clean_names()
revised_D24_crime_hist <- read_excel(here::here("data", "raw", "Cleaned Criminal Hist.xlsx"), sheet = "SU CrimHist") %>% clean_names()

###########################################################################3

# TRIAL SET - NUMBER OF EVENTS PER CASE

trial_set_codes <- revised_D13_case_event_key %>% 
  filter(hearing_event_classification == "Trial Set") %>% 
  select(hearing_code) %>% 
  pull()

case_trial_set_event <- D12_case_event %>% 
  filter(event_code %in% trial_set_codes) %>% 
  group_by(file_number) %>% 
  summarise(no_of_trial_sets = n())

# DEFENDANT AGES

defendant_ages <- D11_filed_cases %>% 
  mutate(
    dob_anon = ymd(dob_anon),
    event_enter_date = mdy(event_enter_date),
    age = interval(dob_anon, event_enter_date) %/% years(1),
    age_group = cut(
      age, breaks = c(0, 18, 30, 40, 50, 60, 80),
      labels = c("<=18", "18-30", "30-40", "40-50", "50-60", ">=60")
    )
  ) %>% 
  select(file_number, defendant_id, age, age_group)

# DEFENDANT SERIOUSNESS

defendant_seriousness <- dfa_by_category %>% 
  select(file_number, defendant_id, seriousness)

# DEFENDANT DRUG CHARGE

defendant_drug_charge <- D21_charge %>% 
  mutate(is_drug_charge = str_detect(current_charge_s, "Uniform Controlled Substances Act")) %>% 
  group_by(file_number) %>% 
  summarise(no_of_drug_charges = sum(as.numeric(is_drug_charge), na.rm = TRUE))

# DEFENDANT DRUG COURT

drug_court_events <- revised_D13_case_event_key %>% 
  filter(str_detect(hearing_event_classification, "Drug Court") == TRUE) %>% 
  select(hearing_code) %>% 
  pull()

defendant_drug_court <- D12_case_event %>% 
  mutate(is_drug_court = event_code %in% drug_court_events) %>% 
  group_by(file_number) %>% 
  summarise(no_of_drug_court = sum(as.numeric(is_drug_court), na.rm = TRUE))

write_csv(case_trial_set_event, here::here("data", "processed", "case_trial_set_event.csv"))
write_csv(defendant_ages, here::here("data", "processed", "defendant_ages.csv"))
write_csv(defendant_seriousness, here::here("data", "processed", "defendant_seriousness.csv"))
write_csv(defendant_drug_charge, here::here("data", "processed", "defendant_drug_charge.csv"))
write_csv(defendant_drug_court, here::here("data", "processed", "defendant_drug_court.csv"))

# dispo_by_category %>% 
#   left_join(represent_charge_by_file, by = c("file_number" = "file_number")) %>% 
#   left_join(case_competency_hearing, by = c("file_number" = "file_number")) %>% 
#   left_join(case_trial_set_event, by = c("file_number" = "file_number")) %>% 
#   left_join(defendant_ages %>% select(-defendant_id, age_group), by = c("file_number" = "file_number")) %>% 
#   left_join(defendant_seriousness %>% select(-defendant_id), by = c("file_number" = "file_number")) %>% 
#   left_join(defendant_drug_charge, by = c("file_number" = "file_number")) %>% 
#   left_join(defendant_drug_court, by = c("file_number" = "file_number"))


