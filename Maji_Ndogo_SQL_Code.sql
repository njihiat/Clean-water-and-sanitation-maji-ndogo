/*
	THIS DOCUMENT SHOWS THE SQL QUERIES, VIEWS, JOINS, CTEs, COMMENTS AND SOME RESULT SETS OF THE ANALYSIS ON MAJI NDOGO WATER PROJECT DATABASE.
	THE QUERIES WERE WRITTEN AND RUN ON MYSQL WORKBENCH. 
	PROPER COMMENTS HAVE BEEN ADDED FOR A BETTER UNDERSTANDING OF THE CODE.
    THIS SQL CODE CANNOT BE EXECUTED AS ONE, SOME CODE ARE DEPENDENT ON OTHERS IN AN INSEQUENTIAL ORDER.
*/

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
 #An independent auditor will be assigned to investigate the errors and the report sent to us.
 
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
 
 
 
 #***************++++++++++++++++**************----- PART 2----- *****************+++++++++*************-------------*************
 
 
 
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
    
    #------ START OF A SOLUTION ----
    #There is need to make data driven decision to improve the infrastructure. So we need to rank the sources by the number of people served.
    # Lets exclude the tap in home because its the best and does not need an improvement. 
    SELECT 
		type_of_water_source, 
        SUM(number_of_people_served) AS Total_people_served,
        RANK() OVER(ORDER BY SUM(number_of_people_served) DESC) AS Rank_of_sources
    FROM water_source
    WHERE type_of_water_source <> 'tap_in_home'
    GROUP BY type_of_water_source;
    
/*		shared_tap			11945272		1
		well				4841724			2
		tap_in_home_broken	3799720			3
		river				2362544			4  
        So we need to fix share_tap first, then well. But which taps or wells are we going to fix first? Lets apply RANK per individual sources.*/

SELECT 
	source_id,
    type_of_water_source,
    SUM(number_of_people_served) AS Total_people_served,
    ROW_NUMBER () OVER(PARTITION BY type_of_water_source ORDER BY SUM(number_of_people_served) DESC) AS Rank_of_sources
    # Have used Row_number instead of Rank to make it easy for engineers to keep track of their progress.
FROM water_source
WHERE type_of_water_source <> 'tap_in_home'
GROUP BY source_id, type_of_water_source;


#Lets dig on the visits table and see the hidden story. Check out the time it took to conduct the survey.
SELECT DATEDIFF(MAX(time_of_record), MIN(time_of_record)) AS survey_time
FROM visits;

#The survey took 924 days which is more than two years, incredicle!

#the average queue time for water is
SELECT AVG(time_in_queue)
FROM visits
WHERE time_in_queue != 0; # Zero indicates that the water source a tap in home or others that does not have a queue time. 

#The average queue time is 123 minutes. thats about 2 hours, but that will vary according to the differnt days of the week
#Lets look on how the average distribute on the days of the week. 
SELECT DAYNAME(time_of_record) AS Day_of_week, ROUND(AVG(time_in_queue)) AS Average_queue_time
FROM visits
WHERE time_in_queue != 0
GROUP BY Day_of_week;
		/*	Friday		120
			Saturday	246
			Sunday		82
			Monday		137
			Tuesday		108
			Wednesday	97
			Thursday	105 
	So saturday has the longest queue time and sunday the shortest
    what about the hours?*/
    
SELECT 
	TIME_FORMAT(TIME(time_of_record), '%H:00') AS Hour_of_the_day, 
    ROUND(AVG(time_in_queue)) AS Average_time_in_queue
FROM visits
GROUP BY Hour_of_the_day;
    
    #Lets investigate how queue time changes with the hour of the day in various days
SELECT 
	TIME_FORMAT(TIME(time_of_record), '%H:00') AS Hour_of_the_day,
    ROUND(AVG(
    CASE
		WHEN DAYNAME(time_of_record) = 'Sunday' THEN time_in_queue
        ELSE NULL
	END ), 0)AS Sunday,
    ROUND(AVG(
    CASE
		WHEN DAYNAME(time_of_record) = 'Monday' THEN time_in_queue
        ELSE NULL 
	END), 0) AS Monday,
    ROUND(AVG(
    CASE
		WHEN DAYNAME(time_of_record) = 'Tuesday' THEN time_in_queue
        ELSE NULL
	END ), 0) AS Tuesday,
    ROUND(AVG(
    CASE
		WHEN DAYNAME(time_of_record) = 'Wednesday' THEN time_in_queue
        ELSE NULL
	END ), 0) AS Wednesday,
    ROUND(AVG(
    CASE
		WHEN DAYNAME(time_of_record) = 'Thursday' THEN time_in_queue
        ELSE NULL
	END ), 0) AS Thursday,
    ROUND(AVG(
    CASE
		WHEN DAYNAME(time_of_record) = 'Friday' THEN time_in_queue
        ELSE NULL
	END ), 0) AS Friday,
    ROUND(AVG(
    CASE
		WHEN DAYNAME(time_of_record) = 'Saturday' THEN time_in_queue
        ELSE NULL
	END ), 0) AS Saturday,
    ROUND(AVG(
    CASE
		WHEN DAYNAME(time_of_record) = 'Sunday' THEN time_in_queue
        ELSE NULL
	END ), 0) AS Sunday
FROM visits
WHERE time_in_queue != 0
GROUP BY Hour_of_the_day
ORDER BY Hour_of_the_day ASC;


        
#***************+++++++++++******-------- PART 3 ---------***********++++++++++++++++*************************************
# WEAVING THE DATA THREADS OF MAJI NDOGO'S NARRATIVES.

#The auditor report is out and lets find out if the scores are different

CREATE VIEW incorrect_records AS ( #Created a view called incorrect_records to store all the records with an error
SELECT 
	visits.location_id, 
    visits.record_id,
    employee.employee_name,
    true_water_source_score AS auditors_score, 
    subjective_quality_score AS employee_score,
    statements
FROM auditor_report
JOIN visits
	ON visits.location_id = auditor_report.location_id
JOIN water_quality
	ON water_quality.record_id = visits.record_id
JOIN employee
	ON visits.assigned_employee_id = employee.assigned_employee_id
WHERE 
	visits.visit_count = 1 AND true_water_source_score != subjective_quality_score);

WITH error_count AS ( # This CTE counts the number of mistakes of each employee
SELECT 
	employee_name, 
    COUNT(employee_name) AS errors_made
FROM incorrect_records # This is the view storing records where scores were found to be different
GROUP BY employee_name ),
suspect_list AS ( # This CTE finds the employees with above average errors.
SELECT 
	employee_name,
    errors_made
 FROM error_count
 WHERE errors_made > (SELECT AVG(errors_made) FROM error_count)) # filter records to get those that are above average
 
 SELECT 
	employee_name,
    location_id,
    statements
FROM incorrect_records
WHERE employee_name IN (SELECT employee_name FROM suspect_list) AND statements LIKE '%_cash_%';

/*There are 102 rows with different scores. We had not yet used the water quality table so our results are not affected by the inconstitency,
If there was an error, lets confirm if the water source were recorded correctly.
Lastly we checked who are the employees that made the errors, to see if it was a mistake or it was done on purpose. By using a view (incorrect_records)
 and 2 CTE (error_count and suspect_list) we see that 4 employees made a big number of errors which were above average. On digging deep into
 the statements, we find metion of cash and corruption cases of the employees. The team has dedicated themselves into finding a solution into 
 Maji Ndogo crisis, its hard to uncover this. Though this is not proof, it would need to be escalated for action to be taken*/


SELECT 
	auditor_report.type_of_water_source AS auditor_source, 
    water_source.type_of_water_source AS water_source_type
FROM auditor_report
JOIN visits
	ON visits.location_id = auditor_report.location_id
JOIN water_source
	ON water_source.source_id = visits.source_id
WHERE auditor_report.type_of_water_source != water_source.type_of_water_source;
#The water source was well recorded

# That was epic, so many stories that numbers and characters can tell!!

#************-----------************--------------- PART 4 -----------*****************------------********************
#CHARTING THE COURSE OF MAJI NDOGO'S WATER FUTURE

/*Several tables have information that can be used to visualize how we can tackle this projects.
	The visits table links the source_id with the location id, and includes the time in queue,
    The Water source table has the different type of water source and number of people served,
    The location table has the address, town and province of the water sources,
    The well pollution table has information about water quality of the wells.*/
#Let's find where are our sources, type, number of people served and time in queue.

CREATE VIEW combined_analysis AS # This view assembles data from different tables into one result set.
SELECT
	province_name,
    town_name, 
    location_type,
    type_of_water_source,
    number_of_people_served,
    time_in_queue,
    results
FROM visits
INNER JOIN location
	ON visits.location_id = location.location_id
INNER JOIN water_source
	ON visits.source_id = water_source.source_id
LEFT JOIN well_pollution
	ON visits.source_id = well_pollution.source_id
WHERE visit_count = 1;

# We get 39650 sources. Make it a view inorder for future analysis on the result set.
# Next, we look at the totap population of various provinces per water source type. 
WITH province_total_pop AS (
SELECT
	province_name,
    SUM(number_of_people_served) AS total_population
FROM combined_analysis
GROUP BY province_name)

SELECT 
	ca.province_name,
    ROUND((SUM(CASE WHEN type_of_water_source = 'well'
		THEN number_of_people_served
	ELSE 0 END)*100.0 / pt.total_population), 0) AS well,
   ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home'
		THEN number_of_people_served
	ELSE 0 END)* 100.0 / pt.total_population), 0) AS tap_in_home,
    ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken'
		THEN number_of_people_served
	ELSE 0 END)* 100.0 / pt.total_population),0) AS tap_in_home_broken,
    ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap'
		THEN number_of_people_served
	ELSE 0 END)* 100.0 / pt.total_population), 0) AS shared_taps,
    ROUND((SUM(CASE WHEN type_of_water_source = 'river'
		THEN number_of_people_served
	ELSE 0 END) * 100.0 / pt.total_population), 0) AS river
FROM combined_analysis ca
JOIN province_total_pop pt
	ON pt.province_name = ca.province_name
GROUP BY ca.province_name;

# This creates a pivot table with percentages of people using each water source per province. This shares alot of insight.

#Viewing this table per town will light up the story very much

CREATE TEMPORARY TABLE town_aggregated_table  # Create a temporary table to store the result set
WITH town_total_pop AS (
SELECT
	province_name,
    town_name,
    SUM(number_of_people_served) AS total_population
FROM combined_analysis
GROUP BY province_name, town_name)

SELECT 
	ca.province_name,
    ca.town_name,
    ROUND((SUM(CASE WHEN type_of_water_source = 'well'
		THEN number_of_people_served
	ELSE 0 END)*100.0 / tt.total_population), 0) AS well,
   ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home'
		THEN number_of_people_served
	ELSE 0 END)* 100.0 / tt.total_population), 0) AS tap_in_home,
    ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken'
		THEN number_of_people_served
	ELSE 0 END)* 100.0 / tt.total_population),0) AS tap_in_home_broken,
    ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap'
		THEN number_of_people_served
	ELSE 0 END)* 100.0 / tt.total_population), 0) AS shared_taps,
    ROUND((SUM(CASE WHEN type_of_water_source = 'river'
		THEN number_of_people_served
	ELSE 0 END) * 100.0 / tt.total_population), 0) AS river
FROM combined_analysis ca
JOIN town_total_pop tt
	ON tt.town_name = ca.town_name AND tt.province_name = ca.province_name
GROUP BY ca.province_name, ca.town_name
ORDER BY ca.town_name;

SELECT * FROM town_aggregated_table order by tap_in_home ASC;

# Now that we know what to do and where, let us create a project_progress table to track the progress.

CREATE TABLE project_progress (
project_id SERIAL PRIMARY KEY, # unique so that no sources is visited more than once
source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE,
				#source id should not be null and should refer to the source id of the water source table for data integrity
address VARCHAR(50),
town VARCHAR(30),
province VARCHAR(30),
source_type VARCHAR(50),
improvement VARCHAR(50),  #this is the type of improvement to make at the source
source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')),
			# We limit what can be updated to 3 choices but the default is backlog which means that the project is yet to start.
date_of_completion DATE, # this is the date the team completes a fix.
comments TEXT
);

# We need to update this table with information of the sources to be updated.

SELECT 
	water_source.source_id,
    location.address,
    location.town_name,
    location.province_name,
    water_source.type_of_water_source,
    well_pollution.results
FROM water_source
INNER JOIN visits
	ON visits.source_id = water_source.source_id
INNER JOIN location
	ON visits.location_id = location.location_id
LEFT JOIN well_pollution
	ON visits.source_id = well_pollution.source_id
WHERE visit_count = 1 AND (results != 'Clean' OR type_of_water_source IN ('tap_in_home_broken', 'river')
								OR (type_of_water_source = 'Shared_tap' AND time_in_queue >= 30));
                                
# We got 25398 sources to improve. 
#Let us add these sources into our progress table

INSERT INTO project_progress (source_id, address, town, province, source_type, improvement)
	
SELECT 
	water_source.source_id,
    location.address,
    location.town_name,
    location.province_name,
    water_source.type_of_water_source,
    CASE WHEN results = 'Contaminated: Biological' THEN 'Install UV filters'
		WHEN results = 'Contaminated: Chemical' THEN 'Install RO filters'
        WHEN type_of_water_source = 'river' THEN ' Drill well'
        WHEN type_of_water_source = 'tap_in_home_broken' THEN 'Diagnose Local Infrastructure'
        WHEN type_of_water_source = 'shared_tap' AND time_in_queue >= 30 THEN CONCAT("Install", FLOOR(time_in_queue/30), " taps nearby")
	ELSE NULL END
FROM water_source
INNER JOIN visits
	ON visits.source_id = water_source.source_id
INNER JOIN location
	ON visits.location_id = location.location_id
LEFT JOIN well_pollution
	ON visits.source_id = well_pollution.source_id
WHERE visit_count = 1 AND (results != 'Clean' OR type_of_water_source IN ('tap_in_home_broken', 'river')
								OR (type_of_water_source = 'Shared_tap' AND time_in_queue >= 30));
                                
#Finally we have a table where our engineers can add data into as they also track the progress of the project.


    


