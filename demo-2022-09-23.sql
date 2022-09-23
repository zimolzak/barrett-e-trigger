SELECT top 14 *
  FROM [CDWWork].[Dim].[LabChemTest]
  where sta3n = 580

select count(*)
from [ORD_ElSerag_202208011D].[Src].[CohortCrosswalk]
-- 20315168

select top 10 * from ORD_ElSerag_202208011D.src.CohortCrosswalk
where sta3n = 580

use ORD_ElSerag_202208011D

select top 10 * from [Src].[Chem_LabChem]

-- houston, valuable columns, join to dim.

select top 10 sta3n, icd9sid, icd10sid, PatientSID, EventDateTime, VisitDateTime
from [Src].[Outpat_VDiagnosis]
where sta3n = 580
and VisitDateTime > '2019-01-01'

-- join up now & see what ICD10
-- look for ICD10 of interest

-- select count(*) from  [Src].[Outpat_VDiagnosis]
-- fails, takes too long.

-- 530.81 for GERD


select * from CDWWork.Dim.icd10
where ICD10SID = 1001716825
-- unspec counseling






select * from CDWWork.dim.ICD10
where sta3n = 580 and ICD10Code like 'K21%'


/*
gerd codes houston
ICD10SID
1600049010
1600049011
1001547809
1001547810
*/

select top 100 * from Src.Outpat_VDiagnosis
where ICD10SID in (1600049010,
1600049011,
1001547809,
1001547810)

select top 10 * from
[Src].[OMOPV5Dim_ICD10_CONCEPT]
where ICD10Code like 'K21%' and sta3n = 580

select top 10 * from Src.OMOPV5_CONCEPT  -- different domains like Drug

select top 10 * from Src.OMOPV5_CONDITION_ERA
select top 10 * from Src.OMOPV5_CONDITION_OCCURRENCE  -- interesting for visit dx of multiple types

select top 10 * from Src.OMOPV5_MEASUREMENT  -- I forget
select top 10 * from Src.OMOPV5_OBSERVATION  -- health factors (among many other probably) including smoker. OBSERVATION_SOURCE_VALUE is text column & good.
select top 10 * from Src.OMOPV5_VISIT_DETAIL  -- empty, okay
select top 10 * from Src.OMOPV5_VISIT_OCCURRENCE  -- gets you dates/times only? one row per inpat/outpat visit or something? may not be as useful as condition tables.


/*
100 patients
any VA, not only HOU
ideally who have mult visits (can be before 2016)
esp interest in 2016 - 2018, should have >= 1 vis

T.N. will look at the 7 variables, on said test cohort.

Applica deadl [society ACG/AGA] Nov. Aims:

1. validate, start Jul 2023
2. etc

va cda --> e trig tool for BE but *surveill* specifically.

*/
