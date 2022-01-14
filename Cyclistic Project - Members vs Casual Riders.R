#install packages
install.packages("tidyverse")
install.packages("lubridate")
install.packages("ggplot2")
install.packages("zoo")
install.packages("markdown")
install.packages("here")

# load packages
library(tidyverse)
library(lubridate)
library(ggplot2)
library(zoo)
library(readr)
library(markdown)
library(here)

# upload data
q2_2019 <- read_csv("Data/Raw Data/Divvy_Trips_2019_Q2.csv")
q3_2019 <- read_csv("Data/Raw Data/Divvy_Trips_2019_Q3.csv")
q4_2019 <- read_csv("Data/Raw Data/Divvy_Trips_2019_Q4.csv")
q1_2020 <- read_csv("Data/Raw Data/Divvy_Trips_2020_Q1.csv")

# check column names. will need to match q1_2020 columns as that is the most current
colnames(q1_2020)
colnames(q2_2019)
colnames(q3_2019)
colnames(q4_2019)

# rename appropriate columns
q2_2019 <- rename(q2_2019
                  ,ride_id = "01 - Rental Details Rental ID"
                  ,rideable_type = "01 - Rental Details Bike ID" 
                  ,started_at = "01 - Rental Details Local Start Time"  
                  ,ended_at = "01 - Rental Details Local End Time"  
                  ,start_station_name = "03 - Rental Start Station Name" 
                  ,start_station_id = "03 - Rental Start Station ID"
                  ,end_station_name = "02 - Rental End Station Name" 
                  ,end_station_id = "02 - Rental End Station ID"
                  ,member_casual = "User Type")
q3_2019 <- rename(q3_2019
                  ,ride_id = trip_id
                  ,rideable_type = bikeid 
                  ,started_at = start_time  
                  ,ended_at = end_time  
                  ,start_station_name = from_station_name 
                  ,start_station_id = from_station_id 
                  ,end_station_name = to_station_name 
                  ,end_station_id = to_station_id 
                  ,member_casual = usertype)
q4_2019 <- rename(q4_2019
                  ,ride_id = trip_id
                  ,rideable_type = bikeid 
                  ,started_at = start_time  
                  ,ended_at = end_time  
                  ,start_station_name = from_station_name 
                  ,start_station_id = from_station_id 
                  ,end_station_name = to_station_name 
                  ,end_station_id = to_station_id 
                  ,member_casual = usertype)

# inspect data frames for any inconsistencies
str(q1_2020)
str(q2_2019)
str(q3_2019)
str(q4_2019)

# convert ride_id and rideable_type to character so that they can stack correctly
q2_2019 <-  mutate(q2_2019, ride_id = as.character(ride_id)
                   ,rideable_type = as.character(rideable_type))
q3_2019 <-  mutate(q3_2019, ride_id = as.character(ride_id)
                   ,rideable_type = as.character(rideable_type))
q4_2019 <-  mutate(q4_2019, ride_id = as.character(ride_id)
                   ,rideable_type = as.character(rideable_type))

# stack individual quarter data frames into one big data frame
all_trips <- bind_rows(q2_2019, q3_2019, q4_2019, q1_2020)

# remove lat, long, birthyear, and gender fields as this data was dropped beginning in 2020
all_trips <- all_trips %>%  
  select(-c(start_lat, start_lng, end_lat, end_lng, birthyear, gender, "01 - Rental Details Duration In Seconds Uncapped", "05 - Member Details Member Birthday Year", "Member Gender", "tripduration"))

# inspect new dataframe
colnames(all_trips)
dim(all_trips)
head(all_trips)
str(all_trips)
summary(all_trips)
table(all_trips$member_casual) # can use table for any column

# there are 2 names for members ("member" and "Subscriber) and 2 names for casual riders ("casual" and "Customer"). will need to consolidate to 2 labels
all_trips <-  all_trips %>% 
  mutate(member_casual = recode(member_casual
                                ,"Subscriber" = "member"
                                ,"Customer" = "casual"))

# ensure proper number of observations are assigned
table(all_trips$member_casual)

# add columns that list the date, month, day, and year of each ride so we could aggregate data to a deeper level
all_trips$date <- as.Date(all_trips$started_at) # will be in date format yyyy-mm-dd
all_trips$month <- format(as.Date(all_trips$date), "%m") # will be in character format because of format function
all_trips$day <- format(as.Date(all_trips$date), "%d")
all_trips$year <- format(as.Date(all_trips$date), "%Y")
all_trips$day_of_week <- format(as.Date(all_trips$date), "%A")

# add ride_length column with calculation to all_trips
all_trips$ride_length <- difftime(all_trips$ended_at,all_trips$started_at)

# inspect structure of data frame once more
str(all_trips)

# since there are entries of when bikes were taken out of docks and/or ride_length was negative, need to remove "bad" data. since removing data, create a new version
all_trips_v2 <- all_trips[!(all_trips$start_station_name == "HQ QR" | all_trips$ride_length<0),]

# conduct descriptive analysis
summary(all_trips_v2$ride_length)

# compare members and casual riders
aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual, FUN = mean)
aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual, FUN = median)
aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual, FUN = max)
aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual, FUN = min)

# see average ride length by each day for members vs casual riders
aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual + all_trips_v2$day_of_week, FUN = mean)

# need to fix days of week because out of order
all_trips_v2$day_of_week <- ordered(all_trips_v2$day_of_week, levels=c("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"))

# see again average ride length by each day for members vs casual riders
aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual + all_trips_v2$day_of_week, FUN = mean)

# see average ride length by month for members vs casual riders
aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual + all_trips_v2$month, FUN = mean)

# see number of rides each day for members vs casual riders
aggregate(all_trips_v2$ride_id ~ all_trips_v2$member_casual + all_trips_v2$day_of_week, FUN = length)

#see number of rides per month for members vs casual riders
aggregate(all_trips_v2$ride_id ~ all_trips_v2$member_casual + all_trips_v2$month, FUN = length)

# analyze ridership data by type and weekday
all_trips_v2 %>% 
  mutate(weekday = wday(started_at, label = TRUE)) %>% 
  group_by(member_casual, weekday) %>% 
  summarise(number_of_rides = n()
            ,average_duration = mean(ride_length)) %>% 
  arrange(member_casual, weekday)

# visualize number of rides by type and weekday
all_trips_v2 %>% 
  mutate(weekday = wday(started_at, label = TRUE)) %>% 
  group_by(member_casual, weekday) %>% 
  summarise(number_of_rides = n()
            ,average_duration = mean(ride_length)) %>% 
  arrange(member_casual, weekday)  %>% 
  ggplot(aes(x = weekday, y = number_of_rides, fill = member_casual)) +
  geom_col(position = "dodge") + 
  labs(title = "Number of Rides by the Day of the Week", subtitle = "April 2019 to March 2020", y = "Number of Rides (x10^5)", x = "Day of the Week") +
  scale_fill_discrete(name = "Rider Type", labels=c("Casual", "Member")) +
  scale_y_continuous(breaks = c(0,(1*(10**5)),(2*(10**5)),(3*(10**5)),(4*(10**5)),(5*(10**5))), labels = c("0", "1", "2", "3", "4", "5"), expand = expansion(mult = c(0, .1)))

# visualize average duration by type and weekday
all_trips_v2 %>% 
  mutate(weekday = wday(started_at, label = TRUE)) %>% 
  group_by(member_casual, weekday) %>% 
  summarise(number_of_rides = n()
            ,average_duration = mean(ride_length)) %>% 
  arrange(member_casual, weekday)  %>% 
  ggplot(aes(x = weekday, y = average_duration, fill = member_casual)) +
  geom_col(position = "dodge") +
  labs(title = "Average Ride Duration per Day of the Week", subtitle = "April 2019 to March 2020", y = "Average Ride Duration (s)", x = "Day of the Week") +
  scale_fill_discrete(name = "Rider Type", labels=c("Casual", "Member")) +
  scale_y_continuous(expand = expansion(mult = c(0, .1)))

# visualize average duration by type and month
all_trips_v2 %>% 
  mutate(year_month = as.factor(as.yearmon(date))) %>% 
  group_by(member_casual, year_month) %>% 
  summarise(number_of_rides = n()
            ,average_duration = mean(ride_length)) %>% 
  arrange(member_casual, year_month)  %>% 
  ggplot(aes(x = year_month, y = average_duration, group = member_casual, color = member_casual)) +
  geom_point() + 
  geom_line() + 
  theme(axis.text.x = element_text(angle = 65, hjust = 1)) + #optional. angles x-axis ticks
  labs(title = "Average Ride Length per Month", subtitle = "April 2019 to March 2020", y = "Average Ride Duration (s)", x = "Month", color = "Rider Type") +
  scale_color_hue(labels=c("Casual", "Member")) +
  scale_x_discrete(labels=c("Apr", "May", "Jun", "July", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar"))

# visualize monthly ride counts
all_trips_v2 %>% 
  mutate(year_month = as.factor(as.yearmon(date))) %>% 
  group_by(member_casual, year_month) %>% 
  summarise(number_of_rides = n()
            ,average_duration = mean(ride_length)) %>% 
  arrange(member_casual, year_month)  %>% 
  ggplot(aes(x = year_month, y = number_of_rides, group = member_casual, color = member_casual)) +
  geom_point() + 
  geom_line() + 
  labs(title = "Monthly Ride Counts", subtitle = "April 2019 to March 2020", y = "Number of Rides (x10^5)", x = "Month", color = "Rider Type") +
  scale_color_hue(labels=c("Casual", "Member")) +
  scale_x_discrete(labels=c("Apr", "May", "Jun", "July", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar")) +
  scale_y_continuous(breaks = c(0,(1*(10**5)),(2*(10**5)),(3*(10**5)),(4*(10**5)),(5*(10**5))), labels = c("0", "1", "2", "3", "4", "5"), expand = expansion(mult = c(0, .1)))

# export summary file for further analysis
count_day_of_week <- aggregate(all_trips_v2$ride_id ~ all_trips_v2$member_casual + all_trips_v2$day_of_week, FUN = length)
count_monthly <- aggregate(all_trips_v2$ride_id ~ all_trips_v2$member_casual + all_trips_v2$month, FUN = length)
avg_ride_length_monthly <- aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual + all_trips_v2$month, FUN = mean)
avg_ride_length_day_of_week <- aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual + all_trips_v2$day_of_week, FUN = mean)
write.csv(count_day_of_week, file = 'C:/Users/coola/Documents/Programming/Data Analysis/R/Cyclistic Bike Trip/Output/Data/Count_Day_of_Week.csv')
write.csv(count_monthly, file = 'C:/Users/coola/Documents/Programming/Data Analysis/R/Cyclistic Bike Trip/Output/Data/Count_Monthly.csv')
write.csv(avg_ride_length_monthly, file = 'C:/Users/coola/Documents/Programming/Data Analysis/R/Cyclistic Bike Trip/Output/Data/Avg_Ride_Length_Monthly.csv')
write.csv(avg_ride_length_day_of_week, file = 'C:/Users/coola/Documents/Programming/Data Analysis/R/Cyclistic Bike Trip/Output/Data/Avg_Ride_Length_Day_of_Week.csv')