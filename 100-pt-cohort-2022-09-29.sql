/*
100 patients
any VA, not only HOU
ideally who have mult visits (can be before 2016)
esp interest in 2016 - 2018, should have >= 1 vis

T.N. will look at the 7 variables, on said test cohort.

also:
inpat and outpat both count. But OK to do just outpat if quicker.
Prefer true random sample not SELECT TOP 100 * ...
Cal Year 2016, 17, and 18.

*/


select top 10 * from ORD_ElSerag_202208011D.Src.OMOPV5_VISIT_OCCURRENCE
where VISIT_START_DATE >= '2016-01-01' and VISIT_START_DATE <= '2018-12-31'
