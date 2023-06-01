--make table of icd10
-- for later....
select
ICD10SID, ICDIEN, sta3n, ICD10Code
into ORD_ElSerag_202208011D.Dflt.rv_icd10list
from CDWWork.dim.ICD10
where ICD10Code in ('K21.00', 'K21.01','K21.9')

/*patient list --> retrieve all visits --> all visit dx*/
-- all visits on our 50 patients.
select
v.VisitSID, v.VisitIEN,  v.VisitDateTime,  p.*
into ORD_ElSerag_202208011D.dflt.rv_visits_on_50
from  ORD_ElSerag_202208011D.src.Outpat_Visit as v
right join ORD_ElSerag_202208011D.Dflt.sample_reviewed_n_50 as p
on v.PatientSID = p.patientsid and v.Sta3n = p.sta3n
where VisitDateTime >= '2014-01-01' and VisitDateTime <= '2018-12-31' 
/* NOTE!! FIVE year block of time per TN rec. */
-- 7746

-- now do join to all visit dxs
select
	a.*,
	d.ICD9SID, d.ICD10SID
into ORD_ElSerag_202208011D.dflt.rv_visits_and_dxs
from ORD_ElSerag_202208011D.src.Outpat_VDiagnosis as d
right join ORD_ElSerag_202208011D.dflt.rv_visits_on_50 as a
on a.VisitSID = d.VisitSID and a.sta3n = d.Sta3n
--11019


--drop table ORD_ElSerag_202208011D.Dflt.rv_patient_visit_dx_gerd

--tag which ones are gerd visits
select
	a.*,
	i.ICD10Code, i.ICDIEN
into ORD_ElSerag_202208011D.Dflt.rv_patient_visit_dx_gerd
from ORD_ElSerag_202208011D.Dflt.rv_icd10list as i
right join ORD_ElSerag_202208011D.dflt.rv_visits_and_dxs as a
on a.ICD10SID = i.ICD10SID and a.sta3n = i.Sta3n

-- Just really quick list of everyone who has GERD codes
select distinct
patientssn, patientlastname, patientfirstname, patientsid, sta3n, patienticn, ICD10Code
from ORD_ElSerag_202208011D.Dflt.rv_patient_visit_dx_gerd
where ICD10Code is not null
order by patientlastname
