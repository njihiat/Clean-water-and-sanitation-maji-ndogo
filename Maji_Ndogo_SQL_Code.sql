USE md_water_services;

# to view the table in the database
SHOW TABLES; 

# looking at one of the tables, The tables are labled properly and the data seem to be correct.
SELECT * FROM visits;			
SELECT * FROM location;
SELECT * FROM water_quality;
SELECT * FROM water_source;
SELECT * FROM employee;
SELECT * FROM data_dictionary;

/* Each table was given a descriptive name, The employee table contains records of employees who are given different tasks in this water project
The visit table contains recordds of each visit made to each water source, the time spent in queue was recorded.
The water_quality contains records of different water source quality.
In the water source table, a water source can be a tap in home, broken or working, a well, a shared tap  or a river.
All the description about the columns and how the table relates to each other is recorded in the data dictionary table */

SELECT distinct 
	type_of_water_source
FROM water_source;
# We have tap_in_home, tap_in_home_broken, well, shared_tap, and river water sources.

/* The water source table indicate that a tap_in home for example AkHa00000224 serves 956, well this means that some tap_in_home were
 combined, 160 taps each serving an average of 6 people per home is approximatly 956.




