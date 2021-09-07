# use this script to install any needed R libraries

# joebauer 8-23-2021: adding two packages in order to try and get data out of Omeka's API. 
echo "---installing R packages---"
#old version that is just R script
#install.packages(c("httr", "jsonlite"), repos="https://repo.miserver.it.umich.edu/cran/")
# try the bash version instead:
Rscript -e 'install.packages(c("httr", "jsonlite"), repos="https://repo.miserver.it.umich.edu/cran/")'
echo "---installed R packages---"
