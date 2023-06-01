USE [ORD_ElSerag_202208011D]
GO

DECLARE @return_val int
/*
DECLARE @PatientKey nvarchar(50)
DECLARE @Input1 nvarchar(max)
DECLARE @Input2 nvarchar(max)
DECLARE @Input3 nvarchar(max)
DECLARE @Ref_Date_Col_Name nvarchar(50)
DECLARE @Execute nvarchar(20)
DECLARE @PrintStep nvarchar(10)
DECLARE @InputSrc nvarchar(5)
*/

EXECUTE @return_val = [Dflt].[SmokingPR v4] 
   @PatientKey = 'PatientICN'
  ,@Input1 = '[ORD_ElSerag_202208011D].[Src].[CohortCrosswalk]'
  ,@Input2 = '[ORD_ElSerag_202208011D].[Dflt].[Smoking_health_factors_v1]'
  ,@Input3 = '[ORD_ElSerag_202208011D].[Dflt].[Smoking_coefficients_v3]'
  ,@Ref_Date_Col_Name = '2018-12-31'
  ,@Execute = 'execute'
  ,@PrintStep = '1'  -- I think you really do need to execute each one 0..6 incrementally.
  ,@InputSrc = 'yes'
GO

/*
Step 0: creates 4-ish views like dflt.cdw_dxdata... and cdw_rxdata...
1: create table smoking01 (in dflt, I think). Taking > 1 min.
*/
