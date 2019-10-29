import pandas as pd
from datetime import datetime
# import numpy as np

d12_d13 = pd.read_csv("../data/D12_D13_case_event_stages.csv")
d31 = pd.read_csv("../data/D31_custody_hist.csv")

# sort dataframe d31
d12_d13.sort_values('defendant_id')
d31.sort_values('defendant_id')

# new column as cal_custody_status
d12_d13['cal_custody_status'] = ""
new_custody_stat = ""

# Loop d12_d13 and try to fill the missing values of 'defendant_event_status'
for index1, row1 in d12_d13.iterrows():

    if pd.isna(row1['event_docket_date']) == True or pd.isna(row1['defendant_event_status']) != True:
        continue

    # list with current defendant_id
    def_id = [row1['defendant_id']]

    print(index1)
    # docket date
    docket_date = datetime.strptime(row1['event_docket_date'], '%m/%d/%Y')
    last_history_date = ''

    for index2, row2 in d31.iterrows():
        if row2['defendant_id'] in def_id:
            # current_status_date, current_history_date
            current_status_date = datetime.strptime(row2['current_status_date'], '%m/%d/%Y')
            if pd.isna(row2['status_history_date']) != True:
                status_history_date = datetime.strptime(row2['status_history_date'], '%m/%d/%Y')

            # condition_1 : if docket_date is >= current_status_date than current_status
            if docket_date >= current_status_date:
                new_custody_stat = row2['current_status']

            if pd.isna(row2['status_history_date']) != True:
                # condition_2 : if docket_date is >= status_history_date and < current_status_date than custody_status_history
                if docket_date >= status_history_date and docket_date < current_status_date:
                    new_custody_stat = row2['custody_status_history']

                if last_history_date != '':
                    # condition_3 : if docket_date is <= last_history_date and >= status_history_date than custody_status_history
                    if docket_date < last_history_date and docket_date >= status_history_date:
                        new_custody_stat = row2['custody_status_history']

            # update "defendant_event_status"
            d12_d13.at[index1, 'defendant_event_status'] = new_custody_stat

            # save last history date for next iteration
            last_history_date = status_history_date

    print(row1['defendant_id'])
    del def_id[:]

d12_d13.to_csv('d12_d13.csv')
print('abc')
