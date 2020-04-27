import csv

data = []
with open('KS_jan2020.csv') as f:
  reader = csv.reader(f)
  for row in reader:
    data.append(row)

data[0] = [data[0][0],'month','year',data[0][1]]

with open('../../../derived/UI_claims/KS_monthly_county_UI.csv','w') as g:
  writer = csv.writer(g)
  writer.writerows(data)


