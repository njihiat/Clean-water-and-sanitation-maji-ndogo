#**** --------------- ----------------- ---------- PART 1 ----------------------------------- -------------------- ------*****
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
 combined, 160 taps each serving an average of 6 people per home is approximatly 956.*/
 
 SELECT *
 FROM visits
 WHERE time_in_queue > 500;
 # This is unreal, imagine queuing up for more that 8 hours for water. Surprisingly, other sources have 0 minutes of queue time.
 
 #Which sources are these that have 8 hours of queue time?
 SELECT visits.source_id, type_of_water_source, time_in_queue, number_of_people_served
 FROM visits
 JOIN water_source
 ON visits.source_id = water_source.source_id
 WHERE time_in_queue > 500;
 
 #The sources are shared taps. And they serve a large number of people. This need urgent intervention.
 
/*Looking at the quality table. Its understood that the field surveyor visited the shared taps more than one, other sources were visited
once. There should be no record of second visit for sources with quality score of 10 like tap-in-home. The quality score also include
 the time_in_queue. 
 So it will be an error for a record with quality score of 10 and visit_count is 2.*/
 
 SELECT *
 FROM water_quality
 WHERE subjective_quality_score = 10 AND visit_count = 2;
 #There are 218 errors, it could be a mistake in the recording, this need to be investigated. Errors are normal in any data.
 
 /*Water pollution records pollution cases in each water source, There are clean and contaminated water source. Lets look if there are errors
 It will be an error is a source has biological or chemical contamination but indicated as clean. Sources with biological or pollutant more 
 than 0 and are indicated as clean shows an error*/
 SELECT *
 FROM well_pollution
 WHERE biological > 0.01 AND results = 'Clean';
 
 /*Seems there are records with the description as clean but actually the source are contaminated. This need to be fixed along with those records
 which has a biological value of more than 0.01 but are indicated as clean. */
 SELECT *
 FROM well_pollution
 WHERE description LIKE 'Clean_%' AND biological >0.01;
 
 #There are 38 incorrect records. 
 #First, I updated the description. 
 SET SQL_SAFE_UPDATES = 0;
 UPDATE well_pollution
 SET description = 'Bacteria: E. coli' # do this for Clean Bacteria: Giardia Lamblia also
 WHERE description = 'Clean Bacteria: E. coli'; 
 
 # now the results column need to be updated also
 UPDATE well_pollution
 SET results = 'Contaminated: Biological'
 WHERE biological > 0.01 AND results = 'Clean';
 
 #---------- ------------------------ PART 2 -------------------------------------------------- -----
 #CLUSTERING DATA TO UNVEIL THE MAJI NDOGO WATER CRISIS
 
 #The employee table lacks the emails, at some point they will be needed for communication. Lets add them
 SET SQL_SAFE_UPDATES = 0; 
 UPDATE employee
 SET email = CONCAT(LOWER(REPLACE(employee_name, ' ', '.')), '@ndogowater.gov');
 # 56 Emails have been updated.
 
 # delving deeper into the table, the phone number has some extra characters. There are 13 characters instead of 9. Lets clean it
 UPDATE employee
 SET phone_number = TRIM(phone_number);
 
 # Lets find out how the employee are distributed across the towns
 SELECT town_name, COUNT(employee_name) AS Number_of_employees
 FROM employee
 GROUP BY town_name;
 
 /* this is wat i get for the towns
	Ilanga	3	Rural	29	Lusaka	4 	Zanzibar	4	Dahabu	6
Most of the employees are from rural areas, President Nalendi want me to send a congratulation message to the top three employee who
collected most records.
Lets find out who are they*/
SELECT visits.assigned_employee_id, employee_name, phone_number, email, COUNT(record_id) AS number_of_records
FROM visits
JOIN employee
ON visits.assigned_employee_id = employee.assigned_employee_id
GROUP BY visits.assigned_employee_id
ORDER BY number_of_records DESC 
LIMIT 3 ;
 /* And our top three employees are 
		1	Bello Azibo	+99643864786	bello.azibo@ndogowater.gov	3708
		30	Pili Zola	+99822478933	pili.zola@ndogowater.gov	3676
		34	Rudo Imani	+99046972648	rudo.imani@ndogowater.gov	3539*/

# Off from our employees, lets try to illuminate the way ahead by looking at the location of our water sources.
SELECT province_name, town_name, COUNT(location_id) AS Number_of_sources
FROM location
GROUP BY province_name, town_name
ORDER BY province_name, Number_of_sources DESC;
	/* Its clear most of the water sources are in the rular areas (23740) than Urban (15910). As per town, the rular area are followed
    by Harare (1650), Amina(1090) and Lusaka(1070). By province, the water source are evenly distributed with the highest kilimani(9510)
    and the lowest Hawassa (6030). These results shows that we have enough records to base our decision on*/
    
#Lets dig deep into our data, the water_source table, what story does it tell?
SELECT type_of_water_source, COUNT(source_id) AS number_of_sources
FROM water_source
GROUP BY type_of_water_source;

# There wells are the highest in number (17383). but how many are contaminated?
SELECT COUNT(source_id) FROM well_pollution WHERE results != 'Clean' ;
# 12467 are contaminated, thats a huge number!. 


#Lets find out how many people are served by each water source
SELECT type_of_water_source, ROUND(AVG(number_of_people_served)) AS Average_people_served
FROM water_source
GROUP BY type_of_water_source;

	/*tap_in_home	644 	tap_in_home_broken	649		well	279		shared_tap	2071	river	699.
    The query shows that on average 644 share a tap in home, thats incorrect. Our surveyors combined households and recorded that information
    as one tap, so not 644 people per tap.
    But others are correct, for example 279 people share one well. */
    






