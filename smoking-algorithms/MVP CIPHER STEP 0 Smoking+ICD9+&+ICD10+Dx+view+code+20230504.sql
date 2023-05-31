
CREATE VIEW 
[Dflt].[CDW_DxData_OPC&PTF_Smoking] AS

SELECT DISTINCT
	PatientSID,
	VisitSID as INorOUT_SID,
	VisitDateTime,
	ICD9SID as ICD9SID,
	'OUT' as 'Care',
	PrimarySecondary
FROM
[Database].[Src].[OutPat_vDiagnosis]

UNION

SELECT DISTINCT
	PatientSID,
	VisitSID as INorOUT_SID,
	VisitDateTime,
	ICD9SID as ICD9SID,
	'OUT' as 'Care',
	PrimarySecondary
FROM
	[Database].[Src].[OutPat_WorkloadVDiagnosis]

UNION 

SELECT
	A.PatientSID,
	A.InpatientSID as INorOUT_SID,
	B.AdmitDateTime as VisitDateTime,
	A.ICD9SID,
	'IN-Admit' as 'Care',
	'PrimarySecondary' = CASE
			WHEN B.PrincipalDiagnosisICD9SID = A.ICD9SID
				THEN 'P'
			ELSE 'S'
		END
FROM
	[Database].[Src].[InPat_InpatientDiagnosis] A
	INNER JOIN [Database].[Src].[InPat_Inpatient] B
		ON A.InpatientSID = B.InpatientSID

UNION

SELECT
	A.PatientSID,
	A.InpatientSID as INorOUT_SID,
	B.AdmitDateTime as VisitDateTime,
	A.ICD9SID,
	'IN-Discharge' as 'Care',
	'PrimarySecondary' = CASE
			WHEN B.PrincipalDiagnosisICD9SID = A.ICD9SID
				THEN 'P'
			ELSE 'S'
		END
FROM
	[Database].[Src].[InPat_InpatientDischargeDiagnosis] A
	INNER JOIN [Database].[Src].[InPat_Inpatient] B
		ON A.InpatientSID = B.InpatientSID

GO



USE [Database]
GO


--=======================================================================================
-- StepICD10View00V - Creation of ICD10 View
--=======================================================================================

--Create The View
--- create view ---
CREATE VIEW 
[Dflt].[CDW_DxData_OPC&PTF_Smoking_ICD10] AS

SELECT DISTINCT
	PatientSID,
	VisitSID as INorOUT_SID,
	VisitDateTime,
	ICD10SID as ICD10SID,
	'OUT' as 'Care',
	PrimarySecondary
FROM
[Database].[Src].[OutPat_vDiagnosis]

UNION

SELECT DISTINCT
	PatientSID,
	VisitSID as INorOUT_SID,
	VisitDateTime,
	ICD10SID as ICD10SID,
	'OUT' as 'Care',
	PrimarySecondary
FROM
	[Database].[Src].[OutPat_WorkloadVDiagnosis]

UNION 

SELECT
	A.PatientSID,
	A.InpatientSID as INorOUT_SID,
	B.AdmitDateTime as VisitDateTime,
	A.ICD10SID,
	'IN-Admit' as 'Care',
	'PrimarySecondary' = CASE
			WHEN B.PrincipalDiagnosisICD10SID = A.ICD10SID
				THEN 'P'
			ELSE 'S'
		END
FROM
	[Database].[Src].[InPat_InpatientDiagnosis] A
	INNER JOIN [Database].[Src].[InPat_Inpatient] B
		ON A.InpatientSID = B.InpatientSID

UNION

SELECT
	A.PatientSID,
	A.InpatientSID as INorOUT_SID,
	B.AdmitDateTime as VisitDateTime,
	A.ICD10SID,
	'IN-Discharge' as 'Care',
	'PrimarySecondary' = CASE
			WHEN B.PrincipalDiagnosisICD10SID = A.ICD10SID
				THEN 'P'
			ELSE 'S'
		END
FROM
	[Database].[Src].[InPat_InpatientDischargeDiagnosis] A
	INNER JOIN [Database].[Src].[InPat_Inpatient] B
		ON A.InpatientSID = B.InpatientSID


--=======================================================================================
-- END ICD10 View Creation
--=======================================================================================
GO


