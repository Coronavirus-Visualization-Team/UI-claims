import csv

data = []
with open('NC_UI_data_prelim.csv') as f:
  reader = csv.reader(f)
  for row in reader:
    data.append(row)



for row in data:
  if row[1] == '' and ('2019' in row):
     print(row)
     row[1] = row[0]
     row[0] = ''
  if row[1] == '' and not ('2019' in row):
    row_split = row[0].split(' ')
    if not 'CHANGES' in row_split and not 'AREAS' in row_split:
      try:
        row[1] = row[0].split(' ')[-1]
        lspace = row[0].rfind(' ')
        row[0] = row[0][:lspace]
      except:
        continue

with open ('NC_UI_data_final.csv','w') as f:
  writer = csv.writer(f)
  writer.writerows(data)


