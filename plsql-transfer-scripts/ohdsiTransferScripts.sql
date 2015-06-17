INSERT INTO temp_ohdsi_person (person_id) 
SELECT person_id from person ;

CREATE TABLE temp_ohdsi_person 
    (
     person_id						INTEGER		 NULL , 
     gender_concept_id				INTEGER		 NULL , 
     year_of_birth					INTEGER		 NULL , 
     month_of_birth					INTEGER		NULL, 
     day_of_birth					INTEGER		NULL, 
	 time_of_birth					VARCHAR(10)	NULL,
     race_concept_id				INTEGER		 NULL, 
     ethnicity_concept_id			INTEGER		 NULL, 
     location_id					INTEGER		NULL, 
     provider_id					INTEGER		NULL, 
     care_site_id					INTEGER		NULL, 
     person_source_value			VARCHAR(50) NULL, 
     gender_source_value			VARCHAR(50) NULL,
	 gender_source_concept_id		INTEGER		NULL, 
     race_source_value				VARCHAR(50) NULL, 
	 race_source_concept_id			INTEGER		NULL, 
     ethnicity_source_value			VARCHAR(50) NULL,
	 ethnicity_source_concept_id	INTEGER		NULL
    ) 
;

UPDATE temp_ohdsi_person
SET GENDER_CONCEPT_ID = 8532
from person
WHERE person.person_id = temp_ohdsi_person.person_id
AND person.gender = 'F'

UPDATE temp_ohdsi_person
SET GENDER_CONCEPT_ID = 8507
from person
WHERE person.person_id = temp_ohdsi_person.person_id
AND person.gender = 'M'

UPDATE temp_ohdsi_person
SET GENDER_CONCEPT_ID = 0
from person
WHERE person.person_id = temp_ohdsi_person.person_id
AND person.gender NOT IN ( 'F', 'M' )

UPDATE temp_ohdsi_person
SET year_of_birth =  EXTRACT (YEAR FROM DATE (person.birthdate)),
month_of_birth = EXTRACT (MONTH FROM DATE (person.birthdate)),
day_of_birth = EXTRACT (DAY FROM DATE (person.birthdate))
from person
WHERE person.person_id = temp_ohdsi_person.person_id

UPDATE temp_ohdsi_person
SET race_concept_id = 2060-2 ,
ethnicity_concept_id = 0
from person
WHERE person.person_id = temp_ohdsi_person.person_id

UPDATE temp_ohdsi_person
SET gender_source_value = person.gender
from person
WHERE person.person_id = temp_ohdsi_person.person_id

UPDATE temp_ohdsi_person
SET person_source_value = CONCAT(patient_identifier.patient_id,patient_identifier.identifier) 
from patient_identifier
WHERE patient_identifier.patient_id = temp_ohdsi_person.person_id

CREATE TABLE temp_ohdsi_observation_period 
    ( 
     observation_period_id				INTEGER		 NULL , 
     person_id							INTEGER		 NULL , 
     observation_period_start_date		DATE		 NULL , 
     observation_period_end_date		DATE		 NULL ,
	 period_type_concept_id				INTEGER		 NULL
    ) 
;

drop table temp_ohdsi_observation_period

INSERT INTO temp_ohdsi_observation_period (person_id) 
SELECT DISTINCT person_id from obs ;

CREATE TABLE temp_ohdsi_observation_period_min 
    ( 
     person_id							INTEGER		 NULL , 
     observation_period_start_date		DATE		 NULL 
    ) 
;

INSERT INTO temp_ohdsi_observation_period_min (person_id,observation_period_start_date) select  person_id,min(obs_datetime) from obs group by person_id

UPDATE temp_ohdsi_observation_period
SET observation_period_start_date = temp_ohdsi_observation_period_min.observation_period_start_date
from temp_ohdsi_observation_period_min
WHERE temp_ohdsi_observation_period_min.person_id = temp_ohdsi_observation_period.person_id;

CREATE TABLE temp_ohdsi_observation_period_max 
    ( 
     person_id							INTEGER		 NULL , 
     observation_period_start_date		DATE		 NULL 
    ) 
;

INSERT INTO temp_ohdsi_observation_period_max (person_id,observation_period_start_date) select  person_id,max(obs_datetime) from obs group by person_id

UPDATE temp_ohdsi_observation_period
SET observation_period_end_date = temp_ohdsi_observation_period_max.observation_period_start_date
from temp_ohdsi_observation_period_max
WHERE temp_ohdsi_observation_period_max.person_id = temp_ohdsi_observation_period.person_id;

UPDATE temp_ohdsi_observation_period
SET observation_period_id = SubQuery.Sort_Order
FROM
    (
    SELECT person_id, Row_Number() OVER (ORDER BY person_id) as SORT_ORDER
    FROM temp_ohdsi_observation_period
    ) SubQuery
where SubQuery.person_id = temp_ohdsi_observation_period.person_id

UPDATE temp_ohdsi_observation_period 

SET period_type_concept_id=0 where 1=1;

INSERT INTO ohdsi_person (person_id,gender_concept_id,year_of_birth,month_of_birth,day_of_birth,race_concept_id,ethnicity_concept_id,person_source_value,gender_source_value) 
SELECT person_id,gender_concept_id,year_of_birth,month_of_birth,day_of_birth,race_concept_id,ethnicity_concept_id,person_source_value,gender_source_value from temp_ohdsi_person ;

INSERT INTO ohdsi_observation_period (observation_period_id,person_id,observation_period_start_date,observation_period_end_date,period_type_concept_id) 
SELECT observation_period_id,person_id,observation_period_start_date,observation_period_end_date,period_type_concept_id from temp_ohdsi_observation_period ;


INSERT INTO person (person_id,gender_concept_id,year_of_birth,month_of_birth,day_of_birth,race_concept_id,ethnicity_concept_id,person_source_value,gender_source_value) 
SELECT person_id,gender_concept_id,year_of_birth,month_of_birth,day_of_birth,race_concept_id,ethnicity_concept_id,person_source_value,gender_source_value from ohdsi_person ;

INSERT INTO observation_period (observation_period_id,person_id,observation_period_start_date,observation_period_end_date,period_type_concept_id) 
SELECT observation_period_id,person_id,observation_period_start_date,observation_period_end_date,period_type_concept_id from ohdsi_observation_period ;



select * from temp_ohdsi_person  where GENDER_CONCEPT_ID = 0;
select * from person where person_id = 9347;
select * from patient_identifier
select * from temp_ohdsi_observation_period
select  person_id,min(obs_datetime) from obs group by person_id
select  obs_datetime from obs where person_id=4349
select  min(obs_datetime) from obs where person_id=4603