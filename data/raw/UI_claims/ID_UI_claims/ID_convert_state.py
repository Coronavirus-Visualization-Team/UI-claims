import csv

data = []
with open('tabula-ID-Week16-Current-Benefit-Payout-Report.csv') as f:
  reader = csv.reader(f)
  for row in reader:
    data.append(row)

for row in data:
  row = row[0:11]
  if 'Change From' in row:
    row[0] = 'Weeks Paid Regular UI' if row == data[0] else 'Benefits Paid Regular UI'

with open ('ID_UI_data_final.csv','w') as f:
  writer = csv.writer(f)
  writer.writerows(data)


