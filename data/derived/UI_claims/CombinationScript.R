# Script created by Frank D'Agostino 2020
# Cleaning file for UI claims as part of
# Coronavirus Visualization Team (CVT)

rm(list = ls())
# Clear console

#-------------------------------------------------------------------------------
# Combined CVS Files
#-------------------------------------------------------------------------------

# Import the partially pre-processed data

list_file <- list.files(pattern='*.csv'); list_file
csv_list <- lapply(list_file, read.csv); head(csv_list)

comb_list <- csv_list[[1]]; head(comb_list)

n <- length(csv_list); n
for (i in 2:n) {
  colnames(csv_list[[i]]) <- colnames(comb_list)
  comb_list <- rbind(comb_list, csv_list[[i]])
}

head(comb_list)

write.csv(comb_list,'combined_UI_claims.csv')

##################################################################
