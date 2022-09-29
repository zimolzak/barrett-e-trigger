/*
100 patients
any VA, not only HOU
ideally who have mult visits (can be before 2016)
esp interest in 2016 - 2018, should have >= 1 vis

T.N. will look at the 7 variables, on said test cohort.

also:
inpat and outpat both count. But OK to do just outpat if quicker.
Prefer true random sample not SELECT TOP 100 * ...
Cal Year 2016, 17, and 18.

*/

use ORD_ElSerag_202208011D;


-- RAND() takes an int. I think max int is about 2 billion.
--random.org only goes to 1 billion
-- my seed from random.org is
-- 31032040
select top 10
PERSON_ID, VISIT_START_DATE, VISIT_TYPE_CONCEPT_ID, x_Source_Table
from ORD_ElSerag_202208011D.Src.OMOPV5_VISIT_OCCURRENCE
where VISIT_START_DATE >= '2016-01-01' and VISIT_START_DATE <= '2018-12-31'

-- forget other rand methods. do WHERE RAND(s) > x and also BINARY_CHECKSUM(col)




/******** figure out how to get SSN from omop *********/

select top 10 *
from src.OMOPV5_CohortPERSON_ID

select top 10 * from src.OMOPV5_PERSON  -- person_id, gender etc, x_patientid_primary

select top 10 * from src.OMOPV5Map_SPatient_PERSON  -- patientsid, patienticn, person_id
-- pretty sure that ( icn == patientid_primary )



/******* ok what if not use omop **********/

select
-- VisitSID, sta3n, VisitDateTime, PrimaryStopCodeSID, SecondaryStopCodeSID, ServiceCategory, EncounterType, AppointmentTypeSID, DiagnosisCount, PatientSID
PatientSID, Sta3n, count(*) as outpat_visits
into dflt.n_outpat_visits
from src.Outpat_Visit  -- don't use vdiagnosis because that's 1 row per dx, not 1 per vis.
where VisitDateTime >= '2016-01-01' and VisitDateTime <= '2018-12-31'
group by PatientSID, Sta3n
-- 44 sec not bad



