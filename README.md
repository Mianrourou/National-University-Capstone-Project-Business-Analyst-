# National-University-Capstone-Project-Business-Analyst-
San Diego Parking Meters Pricing and Occupancy Analysis
library(caret)
library(gpairs)
library(corrplot)
#rename the data
data1=treas_parking_payments_2018_datasd
data2=treas_parking_meters_loc_datasd

#rename variable "pole" into "pole_id" in data 2
library(data.table)
setnames(data2, "pole", "pole_id")

#merging data1 and data2 by "pole_id"
Merged_Data <- merge(data1,data2,by="pole_id")

#looking at the merged data
str(Merged_Data)
class(Merged_Data$zone)
is.na(Merged_Data)
mean(Merged_Data)

#adding a new variable called time_start and time_end
Merged_Data$time_start=format(as.POSIXct(Merged_Data$trans_start,"%Y-%M-%D %H:%M:%S") ,format = "%H:%M:%S")
Merged_Data$time_end=format(as.POSIXct(Merged_Data$meter_expire,"%Y-%M-%D %H:%M:%S") ,format = "%H:%M:%S")

#adding a new variable called date
Merged_Data$date=format(as.POSIXct(Merged_Data$trans_start,"%Y-%M-%D %H:%M:%S") ,format = "%D")

#filter Merged data into Downtown only
library(dplyr)
work.data=Merged_Data
dt <- work.data %>%
  filter(zone=="Downtown")


#adding a new variable called period
mutate(dt$period = dt$time_end - dt$time_end)
mutate(period = as.numeric(dt$time_end - dt$time_start, units="mins"))
mutate (period=time_end - time_start)
duration <- as.numeric(difftime(strptime(paste(dt$trans_start),"%Y-%m-%d %H:%M:%S"))
?mutate
dt$period=difftime(dt$time_start,
                      dt$time_end, 
                      "%H:%M:%S")
dt$period=as.numeric(difftime(strptime(paste(dat[,1],dat[,2]),"%Y-%m-%d %H:%M:%S"),
?difftime
?diff
units = c("auto", "secs", "mins", "hours"),

#export merged data to pc
write.csv(Merged_Data,file="merged_data.csv")

#filter data in towndown
filter

View(Merged_Data)

levels(new_data1$zone)
str(Merged_Data)
install.packages("dplyr")
pillar
