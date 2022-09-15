SELECT TOP 12 *
  FROM [ORD_ElSerag_202208011D].[Src].[CohortPatientSID]

select count(*) from ORD_ElSerag_202208011D.Src.CohortPatientSID
--20315168

select top 12 * from src.CohortCrosswalk
--PatientSID	ScrSSN	PatientSSN	PatientICN	PatientIEN	Sta3n

--two column tables are Src.CohortPatient___ :
--icn, sid, ssn
-- plus src.CohortScrSSN

select count(CohortName) as n, CohortName from src.CohortPatientSID
group by CohortName
/*
n	CohortName
20315168	Primary
*/

select top 10 * from [INFORMATION_SCHEMA].[TABLES]
--only 5 rows

select top 10 * from INFORMATION_SCHEMA.VIEWS
-- zero rows

select count(*) from INFORMATION_SCHEMA.COLUMNS
-- 14
