import csv

data = []
with open('tabula-ID-Week16-Current-Benefit-Payout-Report.csv') as f:
  reader = csv.reader(f)
  for row in reader:
    data.append(row)

new_data = []

for row in data:
  if 'Change From' in row:
    row[0] = 'Weeks Paid Regular UI' if row == data[0] else 'Benefits Paid Regular UI'
  if len(row) > 11: 
    row = row[0:11]
    print(row[-1])
  new_data.append(row)

  

with open ('ID_UI_data_final.csv','w') as g:
  writer = csv.writer(g)
  writer.writerows(new_data)


