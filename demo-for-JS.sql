
SELECT TOP 14
      [BCMAMedicationLogSID]
      ,[BCMAMedicationLogIEN]
      ,[BCMADispensedDrugIEN]
      ,[Sta3n]
      ,[PatientSID]
	  , ActionDateTime
      ,[LocalDrugSID]
      ,[DosesOrdered]
      ,[DosesGiven]
      ,[UnitOfAdministration]
  FROM [ORD_ElSerag_202208011D].[Src].[BCMA_BCMADispensedDrug]
  where ActionDateTime > '2010-01-01'

select * from CDWWork.Dim.LocalDrug
where LocalDrugSID = 604166 and Sta3n = 589

/****** join coming ! ******/


select b.patientsid, b.sta3n, b.ActionDateTime, b.LocalDrugSID, b.DosesGiven, b.DosesOrdered, b.UnitOfAdministration,
 d.LocalDrugNameWithDose, d.VAClassification, d.NDC

from

(


SELECT TOP 14
      [BCMAMedicationLogSID]
      ,[BCMAMedicationLogIEN]
      ,[BCMADispensedDrugIEN]
      ,[Sta3n]
      ,[PatientSID]
	  , ActionDateTime
      ,[LocalDrugSID]
      ,[DosesOrdered]
      ,[DosesGiven]
      ,[UnitOfAdministration]
  FROM [ORD_ElSerag_202208011D].[Src].[BCMA_BCMADispensedDrug]
  where ActionDateTime > '2010-01-01'

  ) as b
left join CDWWork.dim.LocalDrug as d
on b.LocalDrugSID = d.LocalDrugSID
order by VAClassification


/*** fake code

select a.*, b.*
from src.whateverlabchem as a
left join dim.labchemtest as b
on a.labchemtestsid = b.labchemtestsid

***/




/*******no join here******/
select * from (
SELECT TOP 14
      [BCMAMedicationLogSID]
      ,[BCMAMedicationLogIEN]
      ,[BCMADispensedDrugIEN]
      ,[Sta3n]
      ,[PatientSID]
	  , ActionDateTime
      ,[LocalDrugSID]
      ,[DosesOrdered]
      ,[DosesGiven]
      ,[UnitOfAdministration]
  FROM [ORD_ElSerag_202208011D].[Src].[BCMA_BCMADispensedDrug]
  where ActionDateTime > '2010-01-01') as x
  where x.LocalDrugSID in (603051, 595056)  -- say "benztropine & quetiapine" or whatever
