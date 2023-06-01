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
   @PatientKey = 'abcd'
  ,@Input1 = 'abcd'
  ,@Input2 = 'abcd'
  ,@Input3 = 'abcd'
  ,@Ref_Date_Col_Name = 'abcd'
  ,@Execute = 'abcd'
  ,@PrintStep = 'abcd'
  ,@InputSrc = 'abcd'
GO
