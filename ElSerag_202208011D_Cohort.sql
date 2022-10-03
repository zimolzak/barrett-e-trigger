----------------------------------------------------------------------
--9/14/2022		SR		ICD based cohort selection
/*

cohort to consist of all patients with at least one visit at any VA location nationwide 
(table Inpat.Inpatient OR table in the Outpat schema, possibly Outpat.VDiagnosis table) from 1/1/2016-12/31/2018.
*/
--SSN
----------------------------------------------------------------------
--rb03
use [ORD_ElSerag_202208011D]
Go

---------------------------------------
--Cohort
---------------------------------------

-------------------------------------------------------------------------------------------------------------------------
declare @StartDate datetime2(0) = CAST('1/1/2016' AS DATETIME2(0)), @EndDate datetime2(0) = CAST('1/1/2019' AS DATETIME2(0));
--1/1/2016-12/31/2018
-------------------------------------------------------------------------------------------------------------------------
--CohortPatientICN: 8583257 rows
-------------------------------------------------------------------------------------------------------------------------
  truncate table Src.CohortPatientICN;
  
  IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME = 'pk_CohortPatientICN')
   alter table Src.CohortPatientICN drop constraint pk_CohortPatientICN; 
  
  IF EXISTS(SELECT * FROM sys.indexes WHERE object_id = object_id('Src.CohortPatientICN') AND NAME ='ix_CohortPatientICN_PatientICN')
   drop index ix_CohortPatientICN_PatientICN on Src.CohortPatientICN;
  
 
  insert into Src.CohortPatientICN with (tablock)(PatientICN, CohortName)
  select distinct
   P.PatientICN
   ,'Primary' as CohortName
  from
(
select patientSID from  CDWWork.Outpat.Visit ov with (nolock) 
where 1=1 and ov.VisitDateTime >= @StartDate and ov.VisitDateTime < @EndDate
UNION 
select patientSID from CDWWork.Inpat.Inpatient inp with (nolock)  
where 1=1 and ( (inp.dischargedatetime >= @StartDate and inp.dischargedatetime < @EndDate) OR 
(inp.dischargedatetime >= @StartDate and inp.dischargedatetime is null) OR
(inp.admitdatetime >= @StartDate and inp.admitdatetime < @EndDate))
  ) 
    as X
   inner join CDWWork.SPatient.SPatient as P with (nolock)     on X.PatientSID = P.PatientSID
   where 1=1
   and P.CDWPossibleTestPatientFlag = 'N'
   and P.PatientSSN is not null
   and P.ScrSSN is not null
   and P.PatientICN is not null
   and P.PatientSID > 0
  
IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME = 'pk_CohortPatientICN')  
 alter table Src.CohortPatientICN 
  add constraint pk_CohortPatientICN primary key (CohortName, PatientICN)
     with (data_compression = page);


-------------------------------------------------------------------------------------------------------------------------
--CohortCrosswalk: 20315168
--select count(*) from src.CohortCrosswalk
-------------------------------------------------------------------------------------------------------------------------
--get all non-test PatientSIDs associated with the ICNs from Src.CohortPatientICN
--truncate and rebuild so we have a distinct cohort list each time we run

truncate table Src.CohortCrosswalk;

IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME = 'pk_CohortCrosswalk')
 alter table Src.CohortCrosswalk drop constraint pk_CohortCrosswalk;

IF EXISTS(SELECT * FROM sys.indexes WHERE object_id = object_id('Src.CohortCrosswalk') AND NAME ='ix_CohortCrosswalk_ScrSSN')
 drop index ix_CohortCrosswalk_ScrSSN on Src.CohortCrosswalk;

insert into Src.CohortCrosswalk with (tablock)(PatientSID, ScrSSN, PatientSSN, PatientICN, PatientIEN, Sta3n)
select distinct
 p.PatientSID
 ,p.ScrSSN
 ,p.PatientSSN
 ,p.PatientICN
 ,p.PatientIEN
 ,p.Sta3n 
from Src.CohortPatientICN as pc with (nolock) 
 join CDWWork.SPatient.SPatient as p with (nolock) 
on p.PatientICN = pc.PatientICN
where p.CDWPossibleTestPatientFlag = 'N'
 and p.PatientSSN is not null
 and p.ScrSSN is not null
 and p.PatientICN is not null
 and p.PatientSID > 0;
 --

IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME = 'pk_CohortCrosswalk')  
 alter table Src.CohortCrosswalk 
  add constraint pk_CohortCrosswalk primary key (PatientSID)
   with (data_compression = page);

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE object_id = object_id('Src.CohortCrosswalk') AND NAME ='ix_CohortCrosswalk_ScrSSN')
 create index ix_CohortCrosswalk_ScrSSN 
  on Src.CohortCrosswalk (ScrSSN)
  include (PatientICN, PatientSID, sta3n, PatientIEN, PatientSSN)
   with (data_compression = page);



-------------------------------------------------------------------------------------------------------------------------
--create listing of cohort PatientSID: 20315168
-------------------------------------------------------------------------------------------------------------------------

truncate table Src.CohortPatientSID;
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME = 'pk_CohortPatientSID')
 alter table Src.CohortPatientSID drop constraint pk_CohortPatientSID;

IF EXISTS(SELECT * FROM sys.indexes WHERE object_id = object_id('Src.CohortPatientSID') AND NAME ='ix_CohortPatientSID_PatientSID')
 drop index ix_CohortPatientSID_PatientSID on Src.CohortPatientSID;

insert into Src.CohortPatientSID with (tablock)
select distinct
    cc.PatientSID
,pc.CohortName
from Src.CohortCrosswalk as cc with (nolock)
join src.CohortPatientICN as pc with (nolock)
on pc.PatientICN = cc.PatientICN;
--

IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME = 'pk_CohortPatientSID')
 alter table Src.CohortPatientSID 
  add constraint pk_CohortPatientSID primary key (CohortName, PatientSID)
  with (data_compression = page);

-------------------------------------------------------------------------------------------------------------------------
--Src.CohortScrSSN: 8583040
-------------------------------------------------------------------------------------------------------------------------
----create listing of cohort ScrSSNs 
truncate table Src.CohortScrSSN;
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME = 'pk_CohortScrSSN')
 alter table Src.CohortScrSSN  drop constraint pk_CohortScrSSN;

IF EXISTS(SELECT * FROM sys.indexes WHERE object_id = object_id('Src.CohortScrSSN') AND NAME ='ix_CohortScrSSN_ScrSSN')
 drop index ix_CohortScrSSN_ScrSSN on Src.CohortScrSSN;
    

insert into Src.CohortScrSSN with (tablock)
select distinct
 cc.ScrSSN
 ,pc.CohortName
from src.CohortCrosswalk as cc with (nolock)
 join src.CohortPatientICN as pc with (nolock) 
  on pc.PatientICN = cc.PatientICN;

IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME = 'pk_CohortScrSSN')  	  
 alter table Src.CohortScrSSN 
  add constraint pk_CohortScrSSN primary key (CohortName, ScrSSN)
   with (data_compression = page);

   -------------------------------------------------------------------------------------------------------------------------
--Src.CohortPatientSSN ****THIS TABLE MAY OR MAY NOT BE POPULATED FROM COHORT CROSSWALK.
-- IT MAY BE POPULATED FROM THE SOURCE THAT IS SSN BASED (USVETS, ETC.)*****
-------------------------------------------------------------------------------------------------------------------------
----create listing of cohort PatientSSNs: 8583070

truncate table Src.CohortPatientSSN;
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME = 'pk_CohortPatientSSN')
 alter table Src.CohortPatientSSN  drop constraint pk_CohortPatientSSN;

IF EXISTS(SELECT * FROM sys.indexes WHERE object_id = object_id('Src.CohortPatientSSN') AND NAME ='ix_CohortPatientSSN_PatientSSN')
 drop index ix_CohortPatientSSN_PatientSSN on Src.CohortPatientSSN;
    

insert into Src.CohortPatientSSN with (tablock)
select distinct
 cc.PatientSSN
 ,pc.CohortName
from src.CohortCrosswalk as cc with (nolock)
 join src.CohortPatientICN as pc with (nolock) 
  on pc.PatientICN = cc.PatientICN;

IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME = 'pk_CohortPatientSSN')  	  
 alter table Src.CohortPatientSSN 
  add constraint pk_CohortPatientSSN primary key (CohortName, PatientSSN)
   with (data_compression = page);

