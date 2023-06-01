/*
AJZ notes, 2023-06-01

How I localized the code to our own study database:

1. replace [Database] with [ORD_ElSerag_202208011D]
2. fix a few typos (or VINCI populated w/ different view names for different projects).

*/

CREATE VIEW 
[Dflt].[CDW_DxData_OPC&PTF_Smoking] AS
/*
Compiles ICD SIDs and dates from these tables:
Outpatient visit, outpatient workload, inpatient (admission) dx, inpatient discharge dx
*/
	SELECT DISTINCT
		PatientSID,
		VisitSID as INorOUT_SID,
		VisitDateTime,
		ICD9SID as ICD9SID,  -- FIXME: uh oh. does this need to change to ICD10SID?
		'OUT' as 'Care',
		PrimarySecondary
	FROM
	[ORD_ElSerag_202208011D].[Src].[OutPat_vDiagnosis]
	UNION

	SELECT DISTINCT
		PatientSID,
		VisitSID as INorOUT_SID,
		VisitDateTime,
		ICD9SID as ICD9SID,
		'OUT' as 'Care',
		PrimarySecondary
	FROM
		[ORD_ElSerag_202208011D].[Src].[OutPat_WorkloadVDiagnosis]
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
		[ORD_ElSerag_202208011D].[Src].[InPat_InpatientDiagnosis] A
		INNER JOIN [ORD_ElSerag_202208011D].[Src].[InPat_Inpatient] B
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
		[ORD_ElSerag_202208011D].[Src].[InPat_InpatDischargeDiagnosis] A  -- This appears to be typo "InPat_Inpatient" -> "InPat_Inpat"
		INNER JOIN [ORD_ElSerag_202208011D].[Src].[InPat_Inpatient] B
			ON A.InpatientSID = B.InpatientSID
GO

USE [ORD_ElSerag_202208011D]
GO




--=======================================================================================
-- StepICD10View00V - Creation of ICD10 View
--=======================================================================================

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
		[ORD_ElSerag_202208011D].[Src].[OutPat_vDiagnosis]
	UNION

	SELECT DISTINCT
		PatientSID,
		VisitSID as INorOUT_SID,
		VisitDateTime,
		ICD10SID as ICD10SID,
		'OUT' as 'Care',
		PrimarySecondary
	FROM
		[ORD_ElSerag_202208011D].[Src].[OutPat_WorkloadVDiagnosis]
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
		[ORD_ElSerag_202208011D].[Src].[InPat_InpatientDiagnosis] A
		INNER JOIN [ORD_ElSerag_202208011D].[Src].[InPat_Inpatient] B
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
		[ORD_ElSerag_202208011D].[Src].[InPat_InpatDischargeDiagnosis] A  -- same typo
		INNER JOIN [ORD_ElSerag_202208011D].[Src].[InPat_Inpatient] B
			ON A.InpatientSID = B.InpatientSID
GO
