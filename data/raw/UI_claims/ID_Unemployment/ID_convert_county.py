import csv

data = []
with open('ID-county-month-12-prelimdata.csv') as f:
  reader = csv.reader(f)
  for row in reader:
    data.append(row)

new_data = []

new_data.append(['County','Month','Year','Labor Force','Unemployed','Rate','Employed'])

county_data = data[8:53]
#

for row in county_data:
  c_data = []
  c_data.append(row[0].split(' ')[2])
  c_data = c_data + ['12','2019']
  c_data = c_data + row[1:5]
  print(c_data)
  new_data.append(c_data)

with open ('ID_monthly_county_unemployment.csv','w') as g:
  writer = csv.writer(g)
  writer.writerows(new_data)


