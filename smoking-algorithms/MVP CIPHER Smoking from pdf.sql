--USE [YourDatabaseName]
--GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author: Charles Stier
-- Create date: 3/1/2017
-- =============================================
-- Description: Procedure: SmokingPR V4
-- Will accept the following input parameters:
-- @Patient Key Your Patient Key Field Name
-- @Input1 Crosswalk Table Name Include [Database].[Schema].[Table] Name
-- @Input2 Healthfactors Table Name Include [Database].[Schema].[Table] Name
-- @Input3 Coefficient Table Name Include [Database].[Schema].[Table] Name
-- @Ref_Date_Col_Name Reference Date Column Name or a date string such as '01/10/2010'
-- @Execute Execute or Print @SQL_
-- @PrintStep Which step to print or execute - '0', '1', '2', etc
-- Views will be printed or recreated in step 0
-- @InputSrc yes IF you would like to use your database for source tables
--
-- Call the Procedure SmokingPR.
-- =============================================
-- MOD: C. Stier 5/24/2017
-- Step 6: Filter out NULL Reference Dates
--==============================================
-- MOD: C. Stier 7/26/2017
-- Change Step 7 to UNPIVOT
-- Add @PatientKey - User to Select Patient Key Field Name
-- =============================================
-- MOD: J. Russo 1/3/2018
-- Added parameter so that study tables could be used in place of CDW or Vinci1
-- =============================================
-- MOD: J. Russo (3/2018)
-- Changed to use new smoking algorithm as well as a date string
--
--MOD: R. Parker (4/2018)
-- Changed names of views (adding _smoking) so they can be created to correspond to field names in this macro without deleting views previously created for use in the study space.
--
--MODL J. Russo (3/2022)
-- Changed step4 to get values from NationalDrug for natonal drugname with dose (previously using nationaldrugnamewithdose from localdrug.))
--
--DROP PROCEDURE [Dflt].[SmokingPR v4]
--GO
CREATE PROCEDURE [Dflt].[SmokingPR v4]
(
--1. Patient Key Your Patient Key Field Name
@PatientKey nvarchar(50),
--2. Crosswalk Table Name Include [Database].[Schema].[Table] Name
@Input1 nvarchar(MAX),
--3. Healthfactors Table Name Include [Database].[Schema].[Table] Name
@Input2 nvarchar(MAX),
--4. Coefficient Table Name Include [Database].[Schema].[Table] Name
@Input3 nvarchar(MAX),
--5. Reference Date Column Name this could be a column or a string with a date format
@Ref_Date_Col_Name nvarchar(50),
--6. Execute or Print
@Execute nvarchar(20),
--7. Step To Print
@PrintStep nvarchar(10),
--8. Pull CDW Data From Your Database?
@InputSrc nvarchar(5)
)
AS
BEGIN
SET NOCOUNT ON;
--Visit Table
DECLARE @Alt_Library nvarchar(max);
DECLARE @Library nvarchar(max);
DECLARE @Schema nvarchar(max);
DECLARE @vDiag_Table nvarchar(max);
DECLARE @workDiag_Table nvarchar(max);
DECLARE @inpatD_Table nvarchar(max);
DECLARE @inpat_Table nvarchar(max);
DECLARE @inpatDDiag_Table nvarchar(max);
DECLARE @rxoutpat_Table nvarchar(max);
DECLARE @rxoutpatFill_Table nvarchar(max);
DECLARE @bcmamedlog_Table nvarchar(max);
DECLARE @bcmadispDrug_Table nvarchar(max);
DECLARE @outpatVisit_Table nvarchar(max);
DECLARE @hf_table nvarchar(max);
--add visit table
--SQL variables based on steps
DECLARE @SQLICD9View00D nvarchar(MAX);
DECLARE @SQLICD9View00V nvarchar(MAX);
DECLARE @SQLICD10View00D nvarchar(MAX);
DECLARE @SQLICD10View00V nvarchar(MAX);
DECLARE @SQLRxDataView00D nvarchar(MAX);
DECLARE @SQLRxDataView00V nvarchar(MAX);
DECLARE @SQL01 nvarchar(MAX);
DECLARE @SQL02 nvarchar(MAX);
DECLARE @SQL03 nvarchar(MAX);
DECLARE @SQL04 nvarchar(MAX);
DECLARE @SQL05 nvarchar(MAX);
DECLARE @SQL06 nvarchar(MAX);
DECLARE @SQL06DV nvarchar(MAX);
DECLARE @SQL06V nvarchar(MAX);
DECLARE @SQL06T nvarchar(MAX);
--Steps with multiple printlines
DECLARE @SQL03P1 nvarchar(MAX);
DECLARE @SQL03P2 nvarchar(MAX);
DECLARE @SQL03P3 nvarchar(MAX);
DECLARE @SQL03P4 nvarchar(MAX);
DECLARE @SQL03P5 nvarchar(MAX);
DECLARE @SQL04P1 nvarchar(MAX);
DECLARE @SQL04P2 nvarchar(MAX);
DECLARE @SQL05P1 nvarchar(MAX);
DECLARE @SQL05P2 nvarchar(MAX);
DECLARE @SQL06P1 nvarchar(MAX);
DECLARE @SQL06P2 nvarchar(MAX);
DECLARE @SQL06P3 nvarchar(MAX);
DECLARE @SQL06P4 nvarchar(MAX);
DECLARE @SQL06P5 nvarchar(MAX);
DECLARE @SQL06P6 nvarchar(MAX);
DECLARE @SQL06P7 nvarchar(MAX);
DECLARE @Printline nvarchar(MAX);
--Step 7 variable to create view
DECLARE @list nvarchar(MAX);
--Parse Library and Schema names from INPUT1
SET @Library = (SELECT Dflt.LibSchemaParseFN (@Input1, 'library'));
SET @Schema = (SELECT Dflt.LibSchemaParseFN (@Input1, 'schema'));
DECLARE @Orig_Library nvarchar(50); --Orig @INPUT1 Library
DECLARE @Orig_Schema nvarchar(50); --Orig @INPUT1 Schema
SET @Orig_Library = @Library;
SET @Orig_Schema = @Schema;
--Choose which Visit table to use in Step 2
--IF looks like ORD, then use [VINCI1] library in certain reference tables
IF SUBSTRING(LOWER(@Library), 1, 3) = 'ord'
SET @Alt_Library = 'VINCI1';
--IF NOT like ORD, then use [CDWWork] library in certain reference tables
ELSE
SET @Alt_Library = 'CDWWork'
--IF @INPUT1 Schema is 'Src' ...
IF lower(@InputSrc) = 'yes'
BEGIN
SET @Schema = 'Dflt';
--Your Alt Library becomes the Input 1 Library and Alt Schema becomes 'Src'
SET @Alt_Library = @Library;
END
-----
--Set up CDW tables Based on Schema
IF lower(@InputSrc) = 'yes'
BEGIN
SET @vDiag_Table = '[' + @Orig_Library + '].[Src].[OutPat_vDiagnosis]'
SET @workDiag_Table ='[' + @Orig_Library + '].[Src].[OutPat_WorkloadVDiagnosis]'
SET @inpatD_Table ='[' + @Orig_Library + '].[Src].[InPat_InpatientDiagnosis]'
SET @inpat_table = '[' + @Orig_Library + '].[Src].[InPat_Inpatient]'
SET @inpatDDiag_Table = '[' + @Orig_Library + '].[Src].[InPat_InpatientDischargeDiagnosis]'
SET @rxoutpat_Table = '[' + @Orig_Library + '].[Src].[Rxout_Rxoutpat]'
SET @rxoutpatFill_Table = '[' + @Orig_Library + '].[Src].[Rxout_RxoutpatFill]'
SET @bcmamedlog_Table = '[' + @Orig_Library + '].[Src].[BCMA_BCMAMedicationLOg]'
SET @bcmadispDrug_Table = '[' + @Orig_Library + '].[Src].[BCMA_BCMADIspensedDrug]'
SET @outpatVisit_Table = '[' + @Orig_Library + '].[Src].[OutPat_VIsit]'
SET @hf_table = '[' + @Orig_Library + '].[Src].[HF_HealthFactor]'
END
ELSE
BEGIN
SET @vDiag_Table = '[' + @Alt_Library + '].[OutPat].[vDiagnosis]'
SET @workDiag_Table ='[' + @Alt_Library + '].[OutPat].[WorkloadVDiagnosis]'
SET @inpatD_Table ='[' + @Alt_Library + '].[InPat].[InpatientDiagnosis]'
SET @inpat_table = '[' + @Alt_Library + '].[InPat].[Inpatient]'
SET @inpatDDiag_Table = '[' + @Alt_Library + '].[Inpat].[InpatientDischargeDiagnosis]'
SET @rxoutpat_Table = '[' + @Alt_Library + '].[Rxout].[Rxoutpat]'
SET @rxoutpatFill_Table = '[' + @Alt_Library + '].[Rxout].[RxoutpatFill]'
SET @bcmamedlog_Table = '[' + @Alt_Library + '].[BCMA].[BCMAMedicationLOg]'
SET @bcmadispDrug_Table = '[' + @Alt_Library + '].[BCMA].[BCMADIspensedDrug]'
SET @outpatVisit_Table = '[' + @Alt_Library + '].[OutPat].[VIsit]'
SET @hf_table = '[' + @Alt_Library + '].[HF].[HealthFactor]'
END
--Step 6 - Set up @List for Smoking06V Creation
--JPR - split this into two possible commands based on type of ref_date_col_name (column or datestring)
IF isdate(@Ref_Date_Col_Name) = 1
BEGIN
SET @list =
stuff ((select distinct ',' +
quotename(column_name)
from yourdatabasename.information_schema.columns
where table_name ='Smoking05' and column_name not in (''+@PatientKey+'','reference_date')
for xml path(''), type).value ('.','VARCHAR(MAX)'),1,1,'');
END
ELSE
BEGIN
SET @list =
stuff ((select distinct ',' +
quotename(column_name)
from yourdatabasename.information_schema.columns
where table_name ='Smoking05' and column_name not in (''+@PatientKey+'',''+ @Ref_Date_Col_Name+'')
for xml path(''), type).value ('.','VARCHAR(MAX)'),1,1,'');
END
--END
--=======================================================================================
--=======================================================================================
--
-----------------------------------------------------------------------------------------
--STEP 0: Create all views needed in processing SmokingPR
-----------------------------------------------------------------------------------------
--
--=======================================================================================
--=======================================================================================
----------------------------------------------------------------------------------------------------------------------
--1.: ICD9 View
----------------------------------------------------------------------------------------------------------------------
-----------------
SET @SQLICD9View00D =
'
-----------------------------------------------------------------------------------------
--STEP 0: Create views needed in processing SmokingPR
-----------------------------------------------------------------------------------------
--
--=======================================================================================
--=======================================================================================
--=======================================================================================
-- StepICD9View00D - Deletion of ICD9 View
--=======================================================================================
USE ' + @Library + ';
DECLARE @@ICD9ViewExists nvarchar(10);
--Only create view IF it doesn''t exist.
IF OBJECT_ID(''' + @Library + '.' + @Schema + '.CDW_DxData_OPC&PTF_Smoking'', ''V'') IS NOT NULL
DROP VIEW [' + @Schema + '].[CDW_DxData_OPC&PTF_Smoking];
--
'
IF lower(@execute) = 'print'
BEGIN
set @SQLICD9View00D = @SQLICD9View00D + 'GO
--';
END;
--
SET @SQLICD9View00V =
'
--=======================================================================================
-- StepICD9View00V - Creation of ICD9 View
--=======================================================================================
--Create The View
--- create view ---
CREATE VIEW
[' + @Schema + '].[CDW_DxData_OPC&PTF_Smoking] AS
SELECT DISTINCT
PatientSID,
VisitSID as INorOUT_SID,
VisitDateTime,
ICD9SID as ICD9SID,
''OUT'' as ''Care'',
PrimarySecondary
FROM
' + @vDiag_Table + '
UNION
SELECT DISTINCT
PatientSID,
VisitSID as INorOUT_SID,
VisitDateTime,
ICD9SID as ICD9SID,
''OUT'' as ''Care'',
PrimarySecondary
FROM
' + @workDiag_Table + '
UNION ALL
SELECT
A.PatientSID,
A.InpatientSID as INorOUT_SID,
B.AdmitDateTime as VisitDateTime,
A.ICD9SID,
''IN-Admit'' as ''Care'',
''PrimarySecondary'' = CASE
WHEN B.PrincipalDiagnosisICD9SID = A.ICD9SID
THEN ''P''
ELSE ''S''
END
FROM
' + @inpatD_Table + ' A
INNER JOIN ' + @inpat_table + ' B
ON A.InpatientSID = B.InpatientSID
UNION
SELECT
A.PatientSID,
A.InpatientSID as INorOUT_SID,
B.AdmitDateTime as VisitDateTime,
A.ICD9SID,
''IN-Discharge'' as ''Care'',
''PrimarySecondary'' = CASE
WHEN B.PrincipalDiagnosisICD9SID = A.ICD9SID
THEN ''P''
ELSE ''S''
END
FROM
' + @inpatDDiag_Table + ' A
INNER JOIN ' + @inpat_table + ' B
ON A.InpatientSID = B.InpatientSID
--=======================================================================================
-- END ICD9 View Creation
--=======================================================================================
'
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
--=======================================================
-- ICD10 Begin
--=======================================================
--
-----------------
IF lower(@execute) = 'print'
BEGIN
SET @SQLICD10View00D = 'go';
END
ELSE
BEGIN
SET @SQLICD10View00D = '';
END
SET @SQLICD10View00D = @SQLICD10View00D +
'
--=======================================================================================
-- StepICD10View00D - Deletion of ICD10 View
--=======================================================================================
USE ' + @Library + ';
--If View exists, delete it.
IF OBJECT_ID(''' + @Library + '.' + @Schema + '.CDW_DxData_OPC&PTF_Smoking_ICD10_Smoking'', ''V'') IS NOT NULL
DROP VIEW [' + @Schema + '].[CDW_DxData_OPC&PTF_Smoking_ICD10_Smoking];
--
'
IF lower(@execute) = 'print'
BEGIN
set @SQLICD10View00D = @SQLICD10View00D + 'GO
--';
END;
--
SET @SQLICD10View00V =
'
--=======================================================================================
-- StepICD10View00V - Creation of ICD10 View
--=======================================================================================
--Create The View
--- create view ---
CREATE VIEW
[' + @Schema + '].[CDW_DxData_OPC&PTF_Smoking_ICD10_Smoking] AS
SELECT DISTINCT
PatientSID,
VisitSID as INorOUT_SID,
VisitDateTime,
ICD10SID as ICD10SID,
''OUT'' as ''Care'',
PrimarySecondary
FROM
' + @vDiag_Table + '
UNION
SELECT DISTINCT
PatientSID,
VisitSID as INorOUT_SID,
VisitDateTime,
ICD10SID as ICD10SID,
''OUT'' as ''Care'',
PrimarySecondary
FROM
' + @workDiag_Table + '
UNION ALL
SELECT
A.PatientSID,
A.InpatientSID as INorOUT_SID,
B.AdmitDateTime as VisitDateTime,
A.ICD10SID,
''IN-Admit'' as ''Care'',
''PrimarySecondary'' = CASE
WHEN B.PrincipalDiagnosisICD10SID = A.ICD10SID
THEN ''P''
ELSE ''S''
END
FROM
' + @inpatD_Table + ' A
INNER JOIN ' + @inpat_table + ' B
ON A.InpatientSID = B.InpatientSID
UNION
SELECT
A.PatientSID,
A.InpatientSID as INorOUT_SID,
B.AdmitDateTime as VisitDateTime,
A.ICD10SID,
''IN-Discharge'' as ''Care'',
''PrimarySecondary'' = CASE
WHEN B.PrincipalDiagnosisICD10SID = A.ICD10SID
THEN ''P''
ELSE ''S''
END
FROM
' + @inpatDDiag_Table + ' A
INNER JOIN ' + @inpat_table + ' B
ON A.InpatientSID = B.InpatientSID
--=======================================================================================
-- END ICD10 View Creation
--=======================================================================================
'
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
--=======================================================
-- RxData Begin
--=======================================================
--
IF lower(@execute) = 'print'
BEGIN
SET @SQLRxDataView00D = 'go';
END
ELSE
BEGIN
SET @SQLRxDataView00D = '';
END
SET @SQLRxDataView00D = @SQLRxDataView00D +
'
--=======================================================================================
-- StepRxDagtaView00D - Deletion of RxData View
--=======================================================================================
USE ' + @Library + ';
--If View exists, delete it.
IF OBJECT_ID(''' + @Library + '.' + @Schema + '.CDW_RxData_OPC&PTF_Smoking'', ''V'') IS NOT NULL
DROP VIEW [' + @Schema + '].[CDW_RxData_OPC&PTF_Smoking];
--
'
IF lower(@execute) = 'print'
BEGIN
set @SQLRxDataView00D = @SQLRxDataView00D + 'GO
--';
END;
--
SET @SQLRxDataView00V =
'
--=======================================================================================
-- StepRxDataView00V - Creation of RxData View
--=======================================================================================
--
CREATE VIEW
['+@Schema+'].[CDW_RxData_OPC&PTF_Smoking] AS
SELECT
A.PatientSID,
B.ReleaseDateTime,
A.LocalDrugSID,
A.RxOutpatSID as OUTorIN_RxSID,
ISNULL(B.DaysSupply,1) as DaysSupply
FROM
' + @rxoutpat_table + ' A
INNER JOIN ' + @rxoutpatFill_Table + ' B
ON A.RxOutpatSID = B.RxOutpatSID
WHERE
B.ReleaseDateTime IS NOT NULL
UNION ALL
SELECT
A.PatientSID,
A.ActionDateTime as ReleaseDateTime,
B.LocalDrugSID,
A.BCMAMedicationLogSID as OUTorIN_RxSID,
1 as ''DaysSupply''
FROM
' + @bcmamedlog_Table + ' A
INNER JOIN ' + @bcmadispDrug_Table + ' B
ON A.BCMAMedicationLogSID = B.BCMAMedicationLogSID
WHERE
A.ActionDateTime IS NOT NULL
--
--=======================================================
-- RxData End
--=======================================================
--
-- End of View Builds - Step 0
--
--
=========================================================================
==============
--
=========================================================================
==============
--
'
--
=========================================================================
==============
--
=========================================================================
==============
--
-- End of View Builds - Step 0
--
--
=========================================================================
==============
--
=========================================================================
==============
--
--
=========================================================================
==============
--
=========================================================================
==============
--
-------------------------------------------------------------------------
----------------
--STEP 1: Get all outpatient and inpatient ICD9 and ICD10 codes for
tobacco use/depEND ence
-------------------------------------------------------------------------
----------------
--
--
=========================================================================
==============
--
=========================================================================
==============
--
SET @SQL01 =
'
-------------------------------------------------------------------------
-------------------
--STEP 1: Get all outpatient and inpatient ICD9 and ICD10 codes for
tobacco use/depEND ence
-------------------------------------------------------------------------
-------------------
USE ' + @Library + ';
--Work table should be same library/Schema as INPUT1 table
--If Output Table Smoking01 exists, delete it.
IF OBJECT_ID(''' + @Library + '.' + @Schema + '.Smoking01'', ''U'') IS
NOT NULL
DROP TABLE [' + @Library + '].[' + @Schema + '].[Smoking01];
;with ICD as
(
SELECT distinct
C.' + @PatientKey + ','
IF isdate(@Ref_Date_Col_Name) = 1
BEGIN
SET @SQL01 = @SQL01 + ' ''+@Ref_Date_Col_Name+'' as
reference_date, '
END
ELSE
BEGIN
SET @SQL01 = @SQL01 + 'C.' + @Ref_Date_Col_Name + ', '
END
SET @SQL01 = @SQL01 + 'convert(date, VisitDateTime) as VisitDateTime,
A.ICD9Code as ICDCode,
Care
FROM
[CDWWork].[Dim].[ICD9] A
INNER JOIN [' + @Library + '].[' + @Schema +
'].[CDW_DxData_OPC&PTF_Smoking] B
ON A.ICD9SID = B.ICD9SID
INNER JOIN ' + @INPUT1 + ' c
ON B.PatientSID=C.PatientSID
WHERE
(B.VisitDateTime IS NOT NULL)
AND VisitDateTime >=''2000-01-01'' AND '
IF isdate(@Ref_Date_Col_Name) = 1
BEGIN
SET @sql01 = @sql01 + 'VisitDateTime <= '''+@ref_date_col_name+''''
END
ELSE
BEGIN
SET @sql01 = @sql01 + 'VisitDateTime <= C.' + @Ref_Date_Col_Name
END
SET @sql01 = @sql01 + ' AND
(ICD9Code LIKE ''305.1%'' OR
ICD9Code LIKE ''V15.82%'' OR
ICD9Code LIKE ''989.84%'')
AND Care in (''OUT'', ''IN-Admit'')
UNION
SELECT distinct
c.' + @PatientKey + ','
IF isdate(@Ref_Date_Col_Name) = 1
BEGIN
SET @SQL01 = @SQL01 + ' ''+@Ref_Date_Col_Name+'' as reference_date,
'
END
ELSE
BEGIN
SET @SQL01 = @SQL01 + 'C.' + @Ref_Date_Col_Name + ', '
END
SET @SQL01 = @SQL01 + '
convert(date, VisitDateTime) as VisitDateTime,
A.ICD10Code as ICDCode,
Care
FROM
[CDWWork].[Dim].[ICD10] A
INNER JOIN [' + @Library + '].[' + @Schema +
'].[CDW_DxData_OPC&PTF_Smoking_ICD10_Smoking] B
ON A.ICD10SID = B.ICD10SID
INNER JOIN ' + @INPUT1 + ' c
ON B.PatientSID=C.PatientSID
WHERE
(B.VisitDateTime IS NOT NULL)
AND VisitDateTime >=''2000-01-01'' AND '
IF isdate(@Ref_Date_Col_Name) = 1
BEGIN
SET @sql01 = @sql01 + 'VisitDateTime <= '''+@ref_date_col_name+''''
END
ELSE
BEGIN
SET @sql01 = @sql01 + 'VisitDateTime <= C.' + @Ref_Date_Col_Name
END
SET @sql01 = @sql01 + ' AND
ICD10code in ( ''f17.200'' , ''z87.891'', ''t65.223a'',
''t65.224a'', ''t65.292a'', ''t65.293a'', ''t65.294a'')
and Care in (''OUT'', ''IN-Admit'')
)
-------------------------------------------------------------------------
----------------
-- Getting the counts of ICD codes and the first and last date of ICD
code
SELECT
' + @PatientKey + ','
IF isdate(@Ref_Date_Col_Name) = 1
BEGIN
SET @SQL01 = @SQL01 + '''+@Ref_Date_Col_Name+'' as
reference_date, '
END
ELSE
BEGIN
SET @SQL01 = @SQL01 + @Ref_Date_Col_Name + ', '
END
SET @SQL01 = @SQL01 + 'MIN(VisitDateTime) as TobICD9_dF,
MAX(VisitDateTime) as TobICD9_dL,COUNT(*) as countTobICD9
INTO
[' + @Library + '].[' + @Schema + '].[Smoking01]
FROM
ICD
GROUP BY
' + @PatientKey +','
IF isdate(@Ref_Date_Col_Name) = 1
BEGIN
SET @SQL01 = @SQL01 + 'reference_date'
END
ELSE
BEGIN
SET @SQL01 = @SQL01 + @Ref_Date_Col_Name
END
set @SQL01 = @SQL01 + '
;
-------------------------------------------------------------------------
-------------------
--END - STEP 1
-------------------------------------------------------------------------
-------------------
---------------------------------------------------------------------
'
--
--
=========================================================================
==============
--
=========================================================================
==============
--
-------------------------------------------------------------------------
----------------
--STEP 2: Get all outpatient and inpatient stop codes for tobacco
counseling/cessation
-------------------------------------------------------------------------
----------------
--
--
=========================================================================
==============
--
=========================================================================
==============
--
SET @SQL02 =
'
--
=========================================================================
==============
--
=========================================================================
==============
-------------------------------------------------------------------------
-------------------
--STEP 2: Get all outpatient and inpatient stop codes for tobacco
counseling/cessation
-------------------------------------------------------------------------
-------------------
USE ' + @Library + ';
--Work table should be same library/Schema as INPUT1 table
--If Output Table Smoking02 exists, delete it.
IF OBJECT_ID(''' + @Library + '.' + @Schema + '.Smoking02'', ''U'') IS
NOT NULL
DROP TABLE [' + @Library + '].[' + @Schema + '].[Smoking02];
;with stp as
(
SELECT DISTINCT C.' + @PatientKey + ','
IF isdate(@Ref_Date_Col_Name) = 1
BEGIN
SET @SQL02 = @SQL02 + ''''+@Ref_Date_Col_Name+''' as
reference_date, '
END
ELSE
BEGIN
SET @SQL02 = @SQL02 + 'C.' + @Ref_Date_Col_Name + ', '
END
SET @SQL02 = @SQL02 + 'convert(date,VisitDateTime) as VisitDateTime
FROM
[CDWWork].[Dim].[StopCode] a
INNER JOIN ' + @outpatVisit_Table + ' b
on a.stopcodesid=b.primarystopcodesid or
a.stopcodesid=b.secondarystopcodesid
INNER JOIN '
+ @INPUT1 + ' c
ON b.PatientSID=c.PatientSID
WHERE (a.StopCode in (''138'', ''707'', ''708''))
AND (b.VisitDateTime IS NOT NULL)
AND b.VisitDateTime >=''2000-01-01'' AND '
IF isdate(@Ref_Date_Col_Name) = 1
BEGIN
SET @sql02 = @sql02 + 'VisitDateTime <=
'''+@ref_date_col_name+''''
END
ELSE
BEGIN
SET @sql02 = @sql02 + 'VisitDateTime <= C.' +
@Ref_Date_Col_Name
END
SET @SQL02 = @SQL02 + '
)
-------------------------------------------------------------------------
----------------
-- Getting the counts of stop codes and the first and last date of stop
codes
SELECT distinct
' + @PatientKey + ','
IF isdate(@Ref_Date_Col_Name) = 1
BEGIN
SET @SQL02 = @SQL02 + ''''+@Ref_Date_Col_Name+''' as
reference_date, '
END
ELSE
BEGIN
SET @SQL02 = @SQL02 + @Ref_Date_Col_Name + ', '
END
SET @SQL02 = @SQL02 + 'MIN(VisitDateTime) as TobClin_dF,
MAX(VisitDateTime) as TobClin_dL,
COUNT(*) as countTobClin
INTO
[' + @Library + '].[' + @Schema + '].[Smoking02]
FROM
stp
GROUP BY
' + @PatientKey + ', '
IF isdate(@Ref_Date_Col_Name) = 1
BEGIN
SET @SQL02 = @SQL02 + 'reference_date'
END
ELSE
BEGIN
SET @SQL02 = @SQL02 + @Ref_Date_Col_Name
END
SET @SQL02 = @SQL02 + '
;
-------------------------------------------------------------------------
-------------------
--END - STEP 2
-------------------------------------------------------------------------
-------------------
---------------------------------------------------------------------
'
-------------------------------------------------------------------------
----------------
--STEP 3: Pulling Health Factors for each patient and merging them with
the new classIFication provided by study team
-------------------------------------------------------------------------
----------------
--
--
=========================================================================
==============
--
=========================================================================
==============
--
SET @SQL03 =
'
-------------------------------------------------------------------------
---------------------------------------------
--STEP 3: Pulling Health Factors for each patient and merging them with
the new classIFication provided by study team
-------------------------------------------------------------------------
---------------------------------------------
--
--Create the worktable
--
USE ' + @Library + ';
--Work table should be same library/Schema as INPUT1 table
--If Output Table Smoking04 exists, delete it.
IF OBJECT_ID(''' + @Library + '.' + @Schema + '.Smoking03'', ''U'') IS
NOT NULL
DROP TABLE [' + @Library + '].[' + @Schema + '].[Smoking03]
;with hf as
(
SELECT DISTINCT
B.' + @PatientKey + ', '
IF isdate(@Ref_Date_Col_Name) = 1
BEGIN
SET @SQL03 = @SQL03 + ''''+@Ref_Date_Col_Name+''' as
reference_date, '
END
ELSE
BEGIN
SET @SQL03 = @SQL03 + 'B.' + @Ref_Date_Col_Name + ', '
END
SET @SQL03 = @SQL03 + '
C.[HealthFactorType],
D.cat_rs,
convert(date,VisitDateTime) as [VisitDateTime]
FROM
' + @hf_table + ' A
INNER JOIN
--input 1
' + @INPUT1 + ' B
ON A.PatientSID=B.PatientSID
INNER JOIN
[CDWWork].[Dim].[HealthFactorType] C
ON A.[HealthFactorTypeSID]=C.[HealthFactorTypeSID]
INNER JOIN
' + @INPUT2 + ' D
ON C.[HealthFactorType]=D.[HealthFactorType]
WHERE
(VisitDateTime IS NOT NULL)
AND VisitDateTime >= ''2000-01-01'' AND '
IF isdate(@Ref_Date_Col_Name) = 1
BEGIN
SET @sql03 = @sql03 + 'VisitDateTime <=
'''+@ref_date_col_name+''''
END
ELSE
BEGIN
SET @sql03 = @sql03 + 'VisitDateTime <= B.' +
@Ref_Date_Col_Name
END
SET @SQL03 = @SQL03 + '
)
-------------------------------------------------------------------------
----------
--Getting all of the Health Factors counts and first and last date of
each.
SELECT DISTINCT
' + @PatientKey + ', '
IF isdate(@Ref_Date_Col_Name) = 1
BEGIN
SET @SQL03 = @SQL03 + ''''+@Ref_Date_Col_Name+''' as
reference_date'
END
ELSE
BEGIN
SET @sql03 = @sql03 + @Ref_Date_Col_Name
END
SET @SQL03 = @SQL03 + ',
count(case when cat_rs =''u'' then 1 END) as count_u_HealthFac,
count(case when cat_rs =''q'' then 1 END) as count_q_HealthFac,
count(case when cat_rs =''w'' then 1 END) as count_w_HealthFac,
count(case when cat_rs =''f'' then 1 END) as count_f_HealthFac,
count(case when cat_rs =''c'' then 1 END) as count_c_HealthFac,
count(case when cat_rs =''7'' then 1 END) as count_7_HealthFac,
count(case when cat_rs =''s'' then 1 END) as count_s_HealthFac,
count(case when cat_rs =''n'' then 1 END) as count_n_HealthFac,
count(case when cat_rs =''chew'' then 1 END) as
count_chew_HealthFac,
count(case when cat_rs =''chew_c'' then 1 END) as
count_chew_c_HealthFac,
count(case when cat_rs =''chew_f'' then 1 END) as
count_chew_f_HealthFac,
count(case when cat_rs =''?'' then 1 END) as count_m_HealthFac
INTO
[' + @Library + '].[' + @Schema + '].[Smoking03]
FROM
hf
GROUP BY
' + @PatientKey + ', '
IF isdate(@Ref_Date_Col_Name) = 1
BEGIN
SET @SQL03 = @SQL03 + 'reference_date'
END
ELSE
BEGIN
SET @SQL03 = @SQL03 + @Ref_Date_Col_Name
END
SET @SQL03 = @SQL03 + ';
--
=========================================================================
==============
--
=========================================================================
==============
-------------------------------------------------------------------------
-------------------
--END - @SQL03 Executable
-------------------------------------------------------------------------
-------------------
'
---------------------------------------------------------------
--
--
=========================================================================
==============
-- End Step 3
--
=========================================================================
==============
--
--
--
=========================================================================
==============
--
=========================================================================
==============
--
-------------------------------------------------------------------------
----------------
--STEP 4: Pulling Medications for quitting smoking
-------------------------------------------------------------------------
----------------
--
--
=========================================================================
==============
--
=========================================================================
==============
--
SET @SQL04 =
'
--
=========================================================================
==============
--
=========================================================================
==============
-------------------------------------------------------------------------
-------------------
--STEP 4: Pulling Medications for quitting smoking
-------------------------------------------------------------------------
-------------------
-----CREATE LIST OF MEDICATIONS ---
USE ' + @Library + ';
--Work table should be same library/Schema as INPUT1 table
--If Output Table Smoking04A exists, delete it.
IF OBJECT_ID(''' + @Library + '.' + @Schema + '.Smoking04A'', ''U'') IS
NOT NULL
DROP TABLE [' + @Library + '].[' + @Schema + '].[Smoking04A];
SELECT LocalDrugSID,
''Bupropion_HCl'' AS LongName,
LocalDrugNameWithDose,
NationalDrugNameWithDose,
TopographySID
INTO [' + @Library + '].[' + @Schema + '].[Smoking04A]
FROM [CDWWork].[Dim].[LocalDrug] a innder join
[CDWWork].[Dim].[NationalDrug] b where a.NationalDrugSID =
b.NationalDrugSID
where
(a.LocalDrugNameWithDose like ''%bupropion%'' AND a.LocalDrugNameWithDose
like ''%hcl%'')
OR
(b.DrugNameWithDose like ''%bupropion%'' AND b.DrugNameWithDose like
''%hcl%'')
UNION ALL
SELECT LocalDrugSID,
''Bupropion_HBr'' AS LongName,
LocalDrugNameWithDose,
NationalDrugNameWithDose,
TopographySID
FROM [CDWWork].[Dim].[LocalDrug] a innder join
[CDWWork].[Dim].[NationalDrug] b where a.NationalDrugSID =
b.NationalDrugSID
WHERE
(LocalDrugNameWithDose like ''%bupropion%'' AND LocalDrugNameWithDose
like ''%hbr%'')
OR
(b.DrugNameWithDose like ''%bupropion%'' AND b.DrugNameWithDose like
''%hbr%'')
UNION ALL
SELECT LocalDrugSID,
''Varenicline'' AS LongName,
LocalDrugNameWithDose,
NationalDrugNameWithDose,
TopographySID
FROM [CDWWork].[Dim].[LocalDrug]
WHERE
(LocalDrugNameWithDose like ''%Varenicline%'' OR NationalDrugNameWithDose
like ''%Varenicline%'')
UNION ALL
SELECT LocalDrugSID,
''Clonidine_HCl'' AS LongName,
LocalDrugNameWithDose,
NationalDrugNameWithDose,
TopographySID
FROM CDWWork].[Dim].[LocalDrug] a innder join
[CDWWork].[Dim].[NationalDrug] b where a.NationalDrugSID =
b.NationalDrugSID
WHERE
(LocalDrugNameWithDose like ''%Clonidine%'' AND LocalDrugNameWithDose
like ''%hcl%'')
OR
(b.DrugNameWithDose like ''%Clonidine%'' AND b.DrugNameWithDose like
''%hcl%'')
UNION ALL
SELECT LocalDrugSID,
''Nicotine'' AS LongName,
LocalDrugNameWithDose,
NationalDrugNameWithDose,
TopographySID
FROM [CDWWork].[Dim].[LocalDrug]
WHERE
(LocalDrugNameWithDose like ''%Nicotine%'' OR NationalDrugNameWithDose
like ''%Nicotine%'')
UNION ALL
SELECT LocalDrugSID,
''Nortriptyline'' AS LongName,
LocalDrugNameWithDose,
NationalDrugNameWithDose,
TopographySID
FROM [CDWWork].[Dim].[LocalDrug]
WHERE
(LocalDrugNameWithDose like ''%Nortriptyline%'' OR
NationalDrugNameWithDose like ''%Nortriptyline%'')
DELETE FROM [' + @Library + '].[' + @Schema + '].[Smoking04A]
WHERE LocalDrugNameWithDose like ''XX%''
OR LocalDrugNameWithDose like ''zz%''
OR LocalDrugNameWithDose LIKE ''INV%''
OR LocalDrugNameWithDose LIKE ''IRB%''
OR LocalDrugNameWithDose LIKE ''%STUDY%''
OR LocalDrugNameWithDose LIKE ''%ALLHAT%''
OR LocalDrugNameWithDose LIKE ''CSP%''
OR LocalDrugNameWithDose LIKE ''MERIT%''
OR LocalDrugNameWithDose LIKE ''VA COOP%''
--- COMBINE INPATIENT AND OUTPATIENT DRUGS---
--Work table should be same library/Schema as INPUT1 table
--If Output Table Smoking04 exists, delete it.
IF OBJECT_ID(''' + @Library + '.' + @Schema + '.Smoking04'', ''U'') IS NOT NULL
DROP TABLE [' + @Library + '].[' + @Schema + '].[Smoking04];
; with med as
(
SELECT DISTINCT
a.' + @PatientKey + ', '
IF isdate(@Ref_Date_Col_Name) = 1
BEGIN
SET @SQL04 = @SQL04 + ''''+@Ref_Date_Col_Name+''' as reference_date, '
END
ELSE
BEGIN
SET @SQL04 = @SQL04 + 'A.' + @Ref_Date_Col_Name + ', '
END
SET @SQL04 = @SQL04 + 'convert(date, ReleaseDateTime) AS Drug_dt,
D.[LongName],
D.[LocalDrugNameWithDose]
FROM
' + @INPUT1 + ' A
--1
INNER JOIN [' + @Library + '].[' + @Schema + '].[CDW_RxData_OPC&PTF_Smoking] B
ON A.PatientSID= B.PatientSID
INNER JOIN
[' + @Library + '].[' + @Schema + '].[Smoking04A] D
ON B.LocalDrugSID=D.LocalDrugSID
WHERE
(ReleaseDateTime IS NOT NULL)
AND ReleaseDateTime >=''2000-01-01'' AND '
IF isdate(@Ref_Date_Col_Name) = 1
BEGIN
SET @sql04 = @sql04 + 'ReleaseDateTime <= '''+@ref_date_col_name+''''
END
ELSE
BEGIN
SET @sql04 = @sql04 + 'ReleaseDateTime <= A.' + @Ref_Date_Col_Name
END
SET @SQL04 = @SQL04 + '
)
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
--Get the count of medication prescriptions and the first and last date.
SELECT
' + @PatientKey + ', '
IF isdate(@Ref_Date_Col_Name) = 1
BEGIN
SET @sql04 = @sql04 + ''''+@ref_date_col_name+''' as reference_date, '
END
ELSE
BEGIN
SET @sql04 = @sql04 + @Ref_Date_Col_Name +', '
END
SET @SQL04 = @SQL04 + '
Min(case when LongName=''Varenicline'' then Drug_Dt END) as Varenicline_dF,
Max(case when LongName=''Varenicline'' then Drug_Dt END) as Varenicline_dL,
count(case when LongName=''Varenicline'' then 1 END) as count_Varenicline,
Min(case when LongName=''Nicotine'' then Drug_Dt END) as Nicotine_dF,
Max(case when LongName=''Nicotine'' then Drug_Dt END) as Nicotine_dL,
count(case when LongName=''Nicotine'' then 1 END) as count_Nicotine,
Min(case when LongName=''Bupropion_HCl'' then Drug_Dt END) as Bupropion_HCl_dF,
Max(case when LongName=''Bupropion_HCl'' then Drug_Dt END) as Bupropion_HCl_dL,
count(case when LongName=''Bupropion_HCl'' then 1 END) as count_Bupropion_HCl,
Min(case when LongName=''Nortriptyline'' then Drug_Dt END) as Nortriptyline_dF,
Max(case when LongName=''Nortriptyline'' then Drug_Dt END) as Nortriptyline_dL,
count(case when LongName=''Nortriptyline'' then 1 END) as count_Nortriptyline,
Min(case when LongName=''Clonidine_HCl'' then Drug_Dt END) as Clonidine_HCl_dF,
Max(case when LongName=''Clonidine_HCl'' then Drug_Dt END) as Clonidine_HCl_dL,
count(case when LongName=''Clonidine_HCl'' then 1 END) as count_Clonidine_HCl,
Min(case when LongName=''Bupropion_HBr'' then Drug_Dt END) as Bupropion_HBr_dF,
Max(case when LongName=''Bupropion_HBr'' then Drug_Dt END) as Bupropion_HBr_dL,
count(case when LongName=''Bupropion_HBr'' then 1 END) as count_Bupropion_HBr
INTO
[' + @Library + '].[' + @Schema + '].[Smoking04]
FROM
med
GROUP BY
' + @PatientKey + ', '
IF isdate(@Ref_Date_Col_Name) = 1
BEGIN
SET @SQL04 = @SQL04 + 'reference_date'
END
ELSE
BEGIN
SET @SQL04 = @SQL04 + @Ref_Date_Col_Name
END
SET @SQL04 = @SQL04 + ';
--------------------------------------------------------------------------------------------
--END - STEP 4
--------------------------------------------------------------------------------------------
---------------------------------------------------------------------
'
---------------------------------------------------------------------
--=======================================================================================
--=======================================================================================
-- @SQL04 Print Variables - @SQL04P1, @SQL04P2, and @SQL04P3
-- @SQL04 Must be divided into to variables due to PRINT limitation of 8,000 characters.
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
SET @SQL04P1 =
'
--=======================================================================================
--=======================================================================================
--------------------------------------------------------------------------------------------
--STEP 4: Pulling Medications for quitting smoking
--------------------------------------------------------------------------------------------
-----CREATE LIST OF MEDICATIONS ---
USE ' + @Library + ';
--Work table should be same library/Schema as INPUT1 table
--If Output Table Smoking04A exists, delete it.
IF OBJECT_ID(''' + @Library + '.' + @Schema + '.Smoking04A'', ''U'') IS NOT NULL
DROP TABLE [' + @Library + '].[' + @Schema + '].[Smoking04A];
SELECT LocalDrugSID,
''Bupropion_HCl'' AS LongName,
LocalDrugNameWithDose,
NationalDrugNameWithDose,
TopographySID
INTO [' + @Library + '].[' + @Schema + '].[Smoking04A]
FROM [CDWWork].[Dim].[LocalDrug]
where
(LocalDrugNameWithDose like ''%bupropion%'' AND LocalDrugNameWithDose like ''%hcl%'')
OR
(NationalDrugNameWithDose like ''%bupropion%'' AND NationalDrugNameWithDose like ''%hcl%'')
UNION ALL
SELECT LocalDrugSID,
''Bupropion_HBr'' AS LongName,
LocalDrugNameWithDose,
NationalDrugNameWithDose,
TopographySID
FROM [CDWWork].[Dim].[LocalDrug]
WHERE
(LocalDrugNameWithDose like ''%bupropion%'' AND LocalDrugNameWithDose like ''%hbr%'')
OR
(NationalDrugNameWithDose like ''%bupropion%'' AND NationalDrugNameWithDose like ''%hbr%'')
UNION ALL
SELECT LocalDrugSID,
''Varenicline'' AS LongName,
LocalDrugNameWithDose,
NationalDrugNameWithDose,
TopographySID
FROM [CDWWork].[Dim].[LocalDrug]
WHERE
(LocalDrugNameWithDose like ''%Varenicline%'' OR NationalDrugNameWithDose like ''%Varenicline%'')
UNION ALL
SELECT LocalDrugSID,
''Clonidine_HCl'' AS LongName,
LocalDrugNameWithDose,
NationalDrugNameWithDose,
TopographySID
FROM [CDWWork].[Dim].[LocalDrug]
WHERE
(LocalDrugNameWithDose like ''%Clonidine%'' AND LocalDrugNameWithDose like ''%hcl%'')
OR
(NationalDrugNameWithDose like ''%Clonidine%'' AND NationalDrugNameWithDose like ''%hcl%'')
UNION ALL
SELECT LocalDrugSID,
''Nicotine'' AS LongName,
LocalDrugNameWithDose,
NationalDrugNameWithDose,
TopographySID
FROM [CDWWork].[Dim].[LocalDrug]
WHERE
(LocalDrugNameWithDose like ''%Nicotine%'' OR NationalDrugNameWithDose like ''%Nicotine%'')
UNION ALL
SELECT LocalDrugSID,
''Nortriptyline'' AS LongName,
LocalDrugNameWithDose,
NationalDrugNameWithDose,
TopographySID
FROM [CDWWork].[Dim].[LocalDrug]
WHERE
(LocalDrugNameWithDose like ''%Nortriptyline%'' OR NationalDrugNameWithDose like ''%Nortriptyline%'')
DELETE FROM [' + @Library + '].[' + @Schema + '].[Smoking04A]
WHERE LocalDrugNameWithDose like ''XX%''
OR LocalDrugNameWithDose like ''zz%''
OR LocalDrugNameWithDose LIKE ''INV%''
OR LocalDrugNameWithDose LIKE ''IRB%''
OR LocalDrugNameWithDose LIKE ''%STUDY%''
OR LocalDrugNameWithDose LIKE ''%ALLHAT%''
OR LocalDrugNameWithDose LIKE ''CSP%''
OR LocalDrugNameWithDose LIKE ''MERIT%''
OR LocalDrugNameWithDose LIKE ''VA COOP%''
--- COMBINE INPATIENT AND OUTPATIENT DRUGS---
--Work table should be same library/Schema as INPUT1 table
--If Output Table Smoking04 exists, delete it.
IF OBJECT_ID(''' + @Library + '.' + @Schema + '.Smoking04'', ''U'') IS NOT NULL
DROP TABLE [' + @Library + '].[' + @Schema + '].[Smoking04];
; with med as
(
SELECT DISTINCT
a.' + @PatientKey + ', '
IF isdate(@Ref_Date_Col_Name) = 1
BEGIN
SET @SQL04P1 = @SQL04P1 + ''''+@Ref_Date_Col_Name+''' as reference_date, '
END
ELSE
BEGIN
SET @SQL04P1 = @SQL04P1 + 'a.' + @Ref_Date_Col_Name + ', '
END
SET @SQL04P1 = @SQL04P1 + '
convert(date, ReleaseDateTime) AS Drug_dt,
D.[LongName],
D.[LocalDrugNameWithDose]
FROM
' + @INPUT1 + ' A
'
--=========================
SET @SQL04P2 =
' INNER JOIN [' + @Library + '].[' + @Schema + '].[CDW_RxData_OPC&PTF_Smoking] B
ON A.PatientSID= B.PatientSID
INNER JOIN
[' + @Library + '].[' + @Schema + '].[Smoking04A] D
ON B.LocalDrugSID=D.LocalDrugSID
WHERE
(ReleaseDateTime IS NOT NULL)
AND ReleaseDateTime >=''2000-01-01'' AND '
IF isdate(@Ref_Date_Col_Name) = 1
BEGIN
SET @sql04P2 = @sql04P2 + 'ReleaseDateTime <= '''+@ref_date_col_name+''''
END
ELSE
BEGIN
SET @sql04P2 = @sql04P2 + 'ReleaseDateTime <= a.' + @Ref_Date_Col_Name
END
SET @SQL04P2 = @SQL04P2 + '
)
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
--Get the count of medication prescriptions and the first and last date.
SELECT
' + @PatientKey + ', '
IF isdate(@Ref_Date_Col_Name) = 1
BEGIN
SET @sql04P2 = @sql04P2 + ''''+@ref_date_col_name+''' as reference_date, '
END
ELSE
BEGIN
SET @sql04P2 = @sql04P2 + @Ref_Date_Col_Name +', '
END
SET @SQL04P2 = @SQL04P2 + '
Min(case when LongName=''Varenicline'' then Drug_Dt END) as Varenicline_dF,
Max(case when LongName=''Varenicline'' then Drug_Dt END) as Varenicline_dL,
count(case when LongName=''Varenicline'' then 1 END) as count_Varenicline,
Min(case when LongName=''Nicotine'' then Drug_Dt END) as Nicotine_dF,
Max(case when LongName=''Nicotine'' then Drug_Dt END) as Nicotine_dL,
count(case when LongName=''Nicotine'' then 1 END) as count_Nicotine,
Min(case when LongName=''Bupropion_HCl'' then Drug_Dt END) as Bupropion_HCl_dF,
Max(case when LongName=''Bupropion_HCl'' then Drug_Dt END) as Bupropion_HCl_dL,
count(case when LongName=''Bupropion_HCl'' then 1 END) as count_Bupropion_HCl,
Min(case when LongName=''Nortriptyline'' then Drug_Dt END) as Nortriptyline_dF,
Max(case when LongName=''Nortriptyline'' then Drug_Dt END) as Nortriptyline_dL,
count(case when LongName=''Nortriptyline'' then 1 END) as count_Nortriptyline,
Min(case when LongName=''Clonidine_HCl'' then Drug_Dt END) as Clonidine_HCl_dF,
Max(case when LongName=''Clonidine_HCl'' then Drug_Dt END) as Clonidine_HCl_dL,
count(case when LongName=''Clonidine_HCl'' then 1 END) as count_Clonidine_HCl,
Min(case when LongName=''Bupropion_HBr'' then Drug_Dt END) as Bupropion_HBr_dF,
Max(case when LongName=''Bupropion_HBr'' then Drug_Dt END) as Bupropion_HBr_dL,
count(case when LongName=''Bupropion_HBr'' then 1 END) as count_Bupropion_HBr
INTO
[' + @Library + '].[' + @Schema + '].[Smoking04]
FROM
med
GROUP BY
' + @PatientKey + ', '
IF isdate(@Ref_Date_Col_Name) = 1
BEGIN
SET @SQL04P2 = @SQL04P2 + 'reference_date'
END
ELSE
BEGIN
SET @SQL04P2 = @SQL04P2 + @Ref_Date_Col_Name
END
SET @SQL04P2 = @SQL04P2 + '
;
--------------------------------------------------------------------------------------------
--END - STEP 4
--------------------------------------------------------------------------------------------
---------------------------------------------------------------------
'
--
--
--=======================================================================================
--=======================================================================================
--
-----------------------------------------------------------------------------------------
--STEP 5: MERGE ALL TABLES TOGETHER TO GET 1 ROW PER PERSON
-----------------------------------------------------------------------------------------
--
--=======================================================================================
--=======================================================================================
--
SET @SQL05 =
'
-----------------------------------------------------------------------------------------
--STEP 5: MERGE ALL TABLES TOGETHER TO GET 1 ROW PER PERSON
-----------------------------------------------------------------------------------------
--Work table should be same library/Schema as INPUT1 table
USE ' + @Library + ';
--If Output Table Smoking05 exists, delete it.
IF OBJECT_ID(''' + @Library + '.' + @Schema + '.Smoking05'', ''U'') IS NOT NULL
DROP TABLE [' + @Library + '].[' + @Schema + '].[Smoking05];
SELECT B.' + @PatientKey + ', '
IF isdate(@Ref_Date_Col_Name) = 1
BEGIN
SET @SQL05 = @SQL05 + ''''+@Ref_Date_Col_Name+''' as reference_date, '
END
ELSE
BEGIN
SET @SQL05 = @SQL05 + 'B.' + @Ref_Date_Col_Name + ', '
END
SET @SQL05 = @SQL05 + '
--TobICD9_dF, TobICD9_dL,
countTobICD9,
--TobClin_dF, TobClin_dL,
countTobClin,
--HealthFac_u_dF, HealthFac_u_dL,
count_u_HealthFac,
--HealthFac_q_dF, HealthFac_q_dL,
count_q_HealthFac,
--HealthFac_w_dF, HealthFac_w_dL,
count_w_HealthFac,
--HealthFac_f_dF, HealthFac_f_dL,
count_f_HealthFac,
--HealthFac_c_dF, HealthFac_c_dL,
count_c_HealthFac,
--HealthFac_7_dF, HealthFac_7_dL,
count_7_HealthFac,
--HealthFac_s_dF, HealthFac_s_dL,
count_s_HealthFac,
--HealthFac_n_dF, HealthFac_n_dL,
count_n_HealthFac,
--HealthFac_m_dF, HealthFac_m_dL,
count_m_HealthFac,
--HealthFac_chew_dF, HealthFac_chew_dL,
count_chew_Healthfac,
--HealthFac_chew_c_dF, HealthFac_chew_c_dL,
count_chew_c_Healthfac,
--HealthFac_chew_f_dF, HealthFac_chew_f_dL,
count_chew_f_Healthfac,
--Varenicline_dF, Varenicline_dL,
count_Varenicline,
--Nicotine_dF, Nicotine_dL,
count_Nicotine,
--Bupropion_HCl_dF, Bupropion_HCl_dL,
count_Bupropion_HCl,
--Nortriptyline_dF, Nortriptyline_dL,
count_Nortriptyline,
--Clonidine_HCl_dF, Clonidine_HCl_dL,
count_Clonidine_HCl,
--Bupropion_HBr_dF, Bupropion_HBr_dL,
count_Bupropion_HBr,
CASE WHEN count_n_healthfac > count_c_healthfac and count_n_healthfac > (COUNT_F_HEALTHFAC + COUNT_U_HEALTHFAC + COUNT_Q_HEALTHFAC + COUNT_7_HEALTHFAC + COUNT_S_HEALTHFAC)
then 1 ELSE 0 END as never_r,
CASE WHEN (COUNT_F_HEALTHFAC + COUNT_U_HEALTHFAC + COUNT_Q_HEALTHFAC + COUNT_7_HEALTHFAC + COUNT_S_HEALTHFAC) > count_c_healthfac
and (COUNT_F_HEALTHFAC + COUNT_U_HEALTHFAC + COUNT_Q_HEALTHFAC + COUNT_7_HEALTHFAC + COUNT_S_HEALTHFAC) > count_n_healthfac then 1 ELSE 0 END as former_r,
CASE WHEN count_c_healthfac > count_n_healthfac and count_c_healthfac > (COUNT_F_HEALTHFAC + COUNT_U_HEALTHFAC + COUNT_Q_HEALTHFAC + COUNT_7_HEALTHFAC + COUNT_S_HEALTHFAC)
then 1 ELSE 0 END as current_r,
CASE WHEN (countTobICD9 is null and countTobClin is null and count_u_HealthFac is null and count_q_HealthFac is null and count_w_HealthFac is null and
count_f_HealthFac is null and count_c_HealthFac is null and count_7_HealthFac is null and count_s_HealthFac is null and count_n_HealthFac is null and
count_m_HealthFac is null and count_chew_Healthfac is null and count_chew_c_Healthfac is null and count_chew_f_Healthfac is null and count_Varenicline is null and
count_Nicotine is null and count_Bupropion_HCl is null and count_Nortriptyline is null and count_Clonidine_HCl is null and count_Bupropion_HBr is null) THEN 1 ELSE 0 END AS missing,
1 as Intercept
INTO [' + @Library + '].[' + @Schema + '].[Smoking05]
FROM ' + @INPUT1 + ' B
LEFT JOIN
[' + @Library + '].[' + @Schema + '].[Smoking01] C
ON B.' + @PatientKey + '=C.' + @PatientKey
IF isdate(@Ref_Date_Col_Name) = 0
BEGIN
SET @SQL05 = @SQL05 + ' AND B.' + @Ref_Date_Col_Name + '=C.' + @Ref_Date_Col_Name
END
SET @SQL05 = @SQL05 + '
LEFT JOIN
[' + @Library + '].[' + @Schema + '].[Smoking02] D
ON B.' + @PatientKey + '=D.' + @PatientKey
IF isdate(@Ref_Date_Col_Name) = 0
BEGIN
SET @SQL05 = @SQL05 + ' AND B.' + @Ref_Date_Col_Name + '=D.' + @Ref_Date_Col_Name
END
SET @SQL05 = @SQL05 + '
LEFT JOIN
[' + @Library + '].[' + @Schema + '].[Smoking04] E
ON B.' + @PatientKey + '=E.' + @PatientKey
IF isdate(@Ref_Date_Col_Name) = 0
BEGIN
SET @SQL05 = @SQL05 + ' AND B.' + @Ref_Date_Col_Name + '=E.' + @Ref_Date_Col_Name
END
SET @SQL05 = @SQL05 + ' LEFT JOIN
[' + @Library + '].[' + @Schema + '].[Smoking03] G
ON B.' + @PatientKey + '=G.' + @PatientKey
IF isdate(@Ref_Date_Col_Name) = 0
BEGIN
SET @SQL05 = @SQL05 + ' AND B.' + @Ref_Date_Col_Name + '=G.' + @Ref_Date_Col_Name + '
WHERE B.' + @Ref_Date_Col_Name + ' IS NOT NULL '
END
SET @SQL05 = @SQL05 + '
--If the numbers match then every person in your cohort has smoking related data and predicted probability can be generated. If a person does not
--have any data then their smoking status will remain unknown.
--------- PART 1 ENDS HERE ----------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--END - STEP 5
--------------------------------------------------------------------------------------------
---------------------------------------------------------------------
'
---------------------------------------------------------------------
--=======================================================================================
--=======================================================================================
-- @SQL05 Print Variables - @SQL06P1 - @SQL06P5
-- @SQL05 Must be divided into to variables due to PRINT limitation of 8,000 characters.
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
SET @SQL05P1 =
'-----------------------------------------------------------------------------------------
--STEP 5: MERGE ALL TABLES TOGETHER TO GET 1 ROW PER PERSON
-----------------------------------------------------------------------------------------
--Work table should be same library/Schema as INPUT1 table
USE ' + @Library + ';
--If Output Table Smoking05 exists, delete it.
IF OBJECT_ID(''' + @Library + '.' + @Schema + '.Smoking05'', ''U'') IS NOT NULL
DROP TABLE [' + @Library + '].[' + @Schema + '].[Smoking05];
SELECT B.' + @PatientKey + ','
IF isdate(@Ref_Date_Col_Name) = 1
BEGIN
SET @SQL05P1 = @SQL05P1 + 'cast('+''''+@Ref_Date_Col_Name+'''as date) as reference_date, '
END
ELSE
BEGIN
SET @SQL05P1 = @SQL05P1 + 'B.' + @Ref_Date_Col_Name + ', '
END
SET @SQL05P1 = @SQL05P1 + '
--TobICD9_dF, TobICD9_dL,
countTobICD9,
--TobClin_dF, TobClin_dL,
countTobClin,
--HealthFac_u_dF, HealthFac_u_dL,
count_u_HealthFac,
--HealthFac_q_dF, HealthFac_q_dL,
count_q_HealthFac,
--HealthFac_w_dF, HealthFac_w_dL,
count_w_HealthFac,
--HealthFac_f_dF, HealthFac_f_dL,
count_f_HealthFac,
--HealthFac_c_dF, HealthFac_c_dL,
count_c_HealthFac,
--HealthFac_7_dF, HealthFac_7_dL,
count_7_HealthFac,
--HealthFac_s_dF, HealthFac_s_dL,
count_s_HealthFac,
--HealthFac_n_dF, HealthFac_n_dL,
count_n_HealthFac,
--HealthFac_m_dF, HealthFac_m_dL,
count_m_HealthFac,
--HealthFac_chew_dF, HealthFac_chew_dL,
count_chew_Healthfac,
--HealthFac_chew_c_dF, HealthFac_chew_c_dL,
count_chew_c_Healthfac,
--HealthFac_chew_f_dF, HealthFac_chew_f_dL,
count_chew_f_Healthfac,
--Varenicline_dF, Varenicline_dL,
count_Varenicline,
--Nicotine_dF, Nicotine_dL,
count_Nicotine,
--Bupropion_HCl_dF, Bupropion_HCl_dL,
count_Bupropion_HCl,
--Nortriptyline_dF, Nortriptyline_dL,
count_Nortriptyline,
--Clonidine_HCl_dF, Clonidine_HCl_dL,
count_Clonidine_HCl,
--Bupropion_HBr_dF, Bupropion_HBr_dL,
count_Bupropion_HBr,
'
--=====
SET @SQL05P2 =
'CASE WHEN count_n_healthfac > count_c_healthfac and count_n_healthfac > (COUNT_F_HEALTHFAC + COUNT_U_HEALTHFAC + COUNT_Q_HEALTHFAC + COUNT_7_HEALTHFAC + COUNT_S_HEALTHFAC)
then 1 ELSE 0 END as never_r,
CASE WHEN (COUNT_F_HEALTHFAC + COUNT_U_HEALTHFAC + COUNT_Q_HEALTHFAC + COUNT_7_HEALTHFAC + COUNT_S_HEALTHFAC) > count_c_healthfac
and (COUNT_F_HEALTHFAC + COUNT_U_HEALTHFAC + COUNT_Q_HEALTHFAC + COUNT_7_HEALTHFAC + COUNT_S_HEALTHFAC) > count_n_healthfac then 1 ELSE 0 END as former_r,
CASE WHEN count_c_healthfac > count_n_healthfac and count_c_healthfac > (COUNT_F_HEALTHFAC + COUNT_U_HEALTHFAC + COUNT_Q_HEALTHFAC + COUNT_7_HEALTHFAC + COUNT_S_HEALTHFAC)
then 1 ELSE 0 END as current_r,
CASE WHEN (countTobICD9 is null and countTobClin is null and count_u_HealthFac is null and count_q_HealthFac is null and count_w_HealthFac is null and
count_f_HealthFac is null and count_c_HealthFac is null and count_7_HealthFac is null and count_s_HealthFac is null and count_n_HealthFac is null and
count_m_HealthFac is null and count_chew_Healthfac is null and count_chew_c_Healthfac is null and count_chew_f_Healthfac is null and count_Varenicline is null and
count_Nicotine is null and count_Bupropion_HCl is null and count_Nortriptyline is null and count_Clonidine_HCl is null and count_Bupropion_HBr is null) THEN 1 ELSE 0 END AS missing,
1 as Intercept
INTO [' + @Library + '].[' + @Schema + '].[Smoking05]
FROM ' + @INPUT1 + ' B
LEFT JOIN
[' + @Library + '].[' + @Schema + '].[Smoking01] C
ON B.' + @PatientKey + '=C.' + @PatientKey
IF isdate(@Ref_Date_Col_Name) = 0
BEGIN
SET @SQL05P2 = @SQL05P2 + ' AND B.' + @Ref_Date_Col_Name + '=C.' + @Ref_Date_Col_Name
END
SET @SQL05P2 = @SQL05P2 + '
LEFT JOIN
[' + @Library + '].[' + @Schema + '].[Smoking02] D
ON B.' + @PatientKey + '=D.' + @PatientKey
IF isdate(@Ref_Date_Col_Name) = 0
BEGIN
SET @SQL05P2 = @SQL05P2 + ' AND B.' + @Ref_Date_Col_Name + '=D.' + @Ref_Date_Col_Name
END
SET @SQL05P2 = @SQL05P2 + '
LEFT JOIN
[' + @Library + '].[' + @Schema + '].[Smoking04] E
ON B.' + @PatientKey + '=E.' + @PatientKey
IF isdate(@Ref_Date_Col_Name) = 0
BEGIN
SET @SQL05P2 = @SQL05P2 + ' AND B.' + @Ref_Date_Col_Name + '=E.' + @Ref_Date_Col_Name
END
SET @SQL05P2 = @SQL05P2 + ' LEFT JOIN
[' + @Library + '].[' + @Schema + '].[Smoking03] G
ON B.' + @PatientKey + '=G.' + @PatientKey
IF isdate(@Ref_Date_Col_Name) = 0
BEGIN
SET @SQL05P2 = @SQL05P2 + ' AND B.' + @Ref_Date_Col_Name + '=G.' + @Ref_Date_Col_Name + '
WHERE B.' + @Ref_Date_Col_Name + ' IS NOT NULL '
END
SET @SQL05P2 = @SQL05P2 + '
--If the numbers match then every person in your cohort has smoking related data and predicted probability can be generated. If a person does not
--have any data then their smoking status will remain unknown.
--------- PART 1 ENDS HERE ----------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--END - STEP 5
--------------------------------------------------------------------------------------------
---------------------------------------------------------------------
'
--
--
--=======================================================================================
--=======================================================================================
--
-----------------------------------------------------------------------------------------
--STEP 6: -------- PART 2 FOLLOWING PROGRAM TRANSLATED FROM SAS PART 2--
------------------ GET PROBABILITIES--------
-----------------------------------------------------------------------------------------
--
--=======================================================================================
--=======================================================================================
set @SQL06DV = '--
';
IF lower(@execute) = 'print'
BEGIN
set @SQL06DV = @SQL06DV + 'GO
--';
END;
SET @SQL06DV = @SQL06DV +
'
--
-----------------------------------------------------------------------------------------
--STEP 6: -------- PART 2 FOLLOWING PROGRAM TRANSLATED FROM SAS PART 2--
------------------ GET PROBABILITIES--------
-----------------------------------------------------------------------------------------
--
USE ' + @Library + ';
--Work table should be same library/Schema as INPUT1 table
--Drop a View - Smoking06V
IF OBJECT_ID(''' + @Library + '.' + @Schema + '.Smoking06V'', ''V'') IS NOT NULL
DROP VIEW [' + @Schema + '].[Smoking06V];
'
IF lower(@execute) = 'print'
BEGIN
set @SQL06DV = @SQL06DV + 'GO
--';
END;
SET @SQL06V =
'
CREATE VIEW [' + @Schema + '].[Smoking06V] as
SELECT ' + @PatientKey + ', '
IF isdate(@Ref_Date_Col_Name) = 1
BEGIN
SET @SQL06V = @SQL06V + 'reference_date, '
END
ELSE
BEGIN
SET @SQL06V = @SQL06V + @Ref_Date_Col_Name + ', '
END
SET @SQL06V = @SQL06V + 'col,value
from (select * from [' + @Library + '].[' + @Schema + '].[Smoking05]) p
unpivot (value for col in (' +@List+')) as unpvt
'
------------------------------------------
SET @SQL06T = '--
';
IF lower(@execute) = 'print'
BEGIN
set @SQL06T = @SQL06T + 'GO
--';
END;
SET @SQL06T = @SQL06T +
'
USE ' + @Library+ '
';
IF lower(@execute) = 'print'
BEGIN
set @SQL06T = @SQL06T + 'GO
--';
END;
set @SQL06T = @SQL06T + '
--If Output Table Smoking06 exists, delete it.
IF OBJECT_ID(''' + @Library + '.' + @Schema + '.Smoking06JPR'', ''U'') IS NOT NULL
DROP TABLE [' + @Schema + '].[Smoking06JPR];
;with prb as
(
SELECT a.*, value * cast([never] as float) as p1, [value] * cast([former] as float) as p2, value * cast([current] as float) as p3
FROM
[' + @Library + '].[' + @Schema + '].[Smoking06V] A
CROSS JOIN
' + @INPUT3 + ' b
where a.Col = b.Coefficient
)
, exb as
(
SELECT ' + @PatientKey + ', '
IF isdate(@Ref_Date_Col_Name) = 1
BEGIN
SET @SQL06T = @SQL06T + 'reference_date, '
END
ELSE
BEGIN
SET @SQL06T = @SQL06T + @Ref_Date_Col_Name + ', '
END
SET @SQL06T = @SQL06T + ' sum(p1) as p1, sum(p2) as p2, sum(p3) as p3
from prb
GROUP BY ' + @PatientKey + ', '
IF isdate(@Ref_Date_Col_Name) = 1
BEGIN
SET @SQL06T = @SQL06T + 'reference_date '
END
ELSE
BEGIN
SET @SQL06T = @SQL06T + @Ref_Date_Col_Name
END
SET @SQL06T = @SQL06T + '
)
-- 1 = NEVER, 2=FORMER, 3=CURRENT
SELECT ' + @PatientKey + ', '
IF isdate(@Ref_Date_Col_Name) = 1
BEGIN
SET @SQL06T = @SQL06T + 'reference_date, '
END
ELSE
BEGIN
SET @SQL06T = @SQL06T + @Ref_Date_Col_Name + ', '
END
SET @SQL06T = @SQL06T + '
exp(p1) /(exp(p1)+exp(p2) + exp(p3)) as p1,
exp(p2) /(exp(p1)+exp(p2) + exp(p3)) as p2,
exp(p3) /(exp(p1)+exp(p2) + exp(p3)) as p3,
(case when exp(p1) /(exp(p1)+exp(p2) + exp(p3))>= exp(p2) /(exp(p1)+exp(p2) + exp(p3)) and
exp(p1) /(exp(p1)+exp(p2) + exp(p3))>= exp(p3) /(exp(p1)+exp(p2) + exp(p3)) then ''NEVER''
when exp(p2) /(exp(p1)+exp(p2) + exp(p3))> exp(p1) /(exp(p1)+exp(p2) + exp(p3)) and
exp(p2) /(exp(p1)+exp(p2) + exp(p3))>= exp(p3) /(exp(p1)+exp(p2) + exp(p3)) then ''FORMER''
ELSE ''CURRENT'' END ) as smoker
INTO [' + @Library + '].[' + @Schema + '].[Smoking06JPR]
from exb
;
--Remove Temporary View . . .
DROP VIEW [' + @Schema + '].[Smoking06V]
--Remove Temporary Tables . . .
DROP TABLE [' + @Library + '].[' + @Schema + '].[Smoking01];
DROP TABLE [' + @Library + '].[' + @Schema + '].[Smoking02];
DROP TABLE [' + @Library + '].[' + @Schema + '].[Smoking03];
DROP TABLE [' + @Library + '].[' + @Schema + '].[Smoking04];
DROP TABLE [' + @Library + '].[' + @Schema + '].[Smoking05];
DROP TABLE [' + @Library + '].[' + @Schema + '].[Smoking04A];
--------- PART 2 ENDS HERE ----------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--END - STEP 6
--------------------------------------------------------------------------------------------
---------------------------------------------------------------------
'
--
--=======================================================================================
-- Execute or Print Steps
--=======================================================================================
--
-- @Execute should be either 'Execute' or 'Print'
-- 'Print' displays the contents of the @SQL variable
-- 'Execute' executes the @SQL variable
SELECT @Printline = CASE
WHEN @Printstep = '0' THEN @SQLICD9View00D
WHEN @Printstep = '1' THEN @SQL01
WHEN @Printstep = '2' THEN @SQL02
WHEN @Printstep = '3' THEN @SQL03
WHEN @Printstep = '4' THEN @SQL04
WHEN @Printstep = '5' THEN @SQL05
WHEN @Printstep = '6' THEN @SQL06DV
ELSE 'Invalid entry for @PrintStep. Must be between ''0'' and ''7'''
END
IF lower(@Execute) = 'print'
BEGIN
-- Print all views created
IF @Printstep = '0'
BEGIN
PRINT (@SQLICD9View00D);
PRINT (@SQLICD9View00V);
PRINT (@SQLICD10View00D);
PRINT (@SQLICD10View00V);
PRINT (@SQLRxDataView00D);
PRINT (@SQLRxDataView00V);
END;
ELSE
-- Step 3 beyond the 8K limit
IF @Printstep = '3'
BEGIN
PRINT (@SQL03);
END;
ELSE
IF @Printstep = '4'
BEGIN
PRINT (@SQL04P1);
PRINT (@SQL04P2);
END;
ELSE
IF @Printstep = '5'
BEGIN
PRINT (@SQL05P1);
PRINT (@SQL05P2);
END;
ELSE
IF @Printstep = '6'
BEGIN
PRINT (@SQL06DV);
PRINT (@SQL06V);
PRINT (@SQL06T);
END;
ELSE
PRINT @Printline;
END;
ELSE
IF lower(@Execute) = 'execute'
IF @Printstep = '0'
BEGIN
EXEC (@SQLICD9View00D);
EXEC (@SQLICD9View00V);
EXEC (@SQLICD10View00D);
EXEC (@SQLICD10View00V);
EXEC (@SQLRxDataView00D);
EXEC (@SQLRxDataView00V);
END;
ELSE
IF @Printstep = '6'
BEGIN
EXEC (@SQL06DV);
EXEC (@SQL06V);
EXEC (@SQL06T);
END;
ELSE
BEGIN
IF @Printstep between '0' and '6'
Exec (@Printline);
ELSE
PRINT @Printline;
END;
ELSE PRINT 'Invalid entry for @Execute. Must be either ''Execute'' or ''Print''.'
END
GO
