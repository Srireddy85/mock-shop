use SimulationReports
go

create procedure sp_MSOutputResults
	@EmployerGroupID bigint,
	@Method varchar(20) = null
as

begin

-- BCBSMN Method
if @Method = 'MN'

with results as (
select distinct memdos, treatmentcode, name, service_from_date, Provider_ID, SHS_ID, Results, LowProviderId, LowPrice, AvgPrice, HiPrice, Incentive, PotentialSavings, case when allowedamount <= lowprice+lowprice*.15 and allowedamount >= Lowprice-lowprice*.15 then 1 else 4 end as ChosenRank from (
  select t.MEMDOS, t.allowedamount, t.TreatmentCode, tc.name, t.Service_From_Date, t.provider_id, s.SearchId SHS_ID,
     (select sum(1) from CAV22_SIM.dbo.vw_ShoppingHistory_1 v where v.SearchId =s.SearchId) Results,
     (select min(ServiceProviderDistinguishedKey) from CAV22_SIM.dbo.vw_ShoppingHistory_1 v where v.SearchId = s.SearchId and Rank = 1) LowProviderId,
     (select min(AverageCost) from CAV22_SIM.dbo.vw_ShoppingHistory_1 v where v.SearchId = s.SearchId) LowPrice,
     (select avg(AverageCost) from CAV22_SIM.dbo.vw_ShoppingHistory_1 v where v.SearchId = s.SearchId) AvgPrice,
     (select max(AverageCost) from CAV22_SIM.dbo.vw_ShoppingHistory_1 v where v.SearchId = s.SearchId) HiPrice,
     (select case when max(IncentiveAmount) is null then 0 else max(IncentiveAmount) end from CAV22_SIM.dbo.vw_ShoppingHistory_1 v where v.SearchId = s.SearchId) Incentive,
     (select avg(AverageCost) from CAV22_SIM.dbo.vw_ShoppingHistory_1 v where v.SearchId = s.SearchId and IncentiveAmount = 0)-(select min(AverageCost) from CAV22_SIM.dbo.vw_ShoppingHistory_1 v where v.SearchId = s.SearchId) - (select case when max(IncentiveAmount) is null then 0 else max(IncentiveAmount) end from CAV22_SIM.dbo.vw_ShoppingHistory_1 v where v.SearchId = s.SearchId) PotentialSavings
  from SimulationReports.dbo.MS_Memdos t inner join CAV22_SIM.dbo.TreatmentCodes tc on t.treatmentcode = tc.code and t.EmployerGroupID = 914 --update with MEMDOS table
   inner join SimulationReports.dbo.MS_URLs s on t.treatmentcode = s.Treatmentcode and left(t.zipcode,5) = s.ZipCode and s.EmployerGroupID = 914)
   as x) --update with URL table
 
select TreatmentCOde, Name, sum(1) Cases, sum(case when chosenrank <=2 then 1 else 0 end) LowCostCases ,   sum(case when chosenrank <=2 then 1.0 else 0 end) / sum(1.0)  PctLowCost,
 sum(1) - sum(case when chosenrank <=2 then 1 else 0 end) CaseswithPotential, (sum(1) - sum(case when chosenrank <=2 then 1 else 0 end))/sum(1.0) PctWithPot,
  sum(case when isnull(chosenrank,3)>2 then PotentialSavings else 0 end) TotalPotentialSavings,
  sum(case when isnull(chosenrank,3)>2 then PotentialSavings else 0 end)/(sum(1) - sum(case when chosenrank <=2 then 1 else 0 end) ) PotSavPerCase,
  sum(case when isnull(chosenrank,3)>2 then PotentialSavings else 0 end)/(sum(1) - sum(case when chosenrank <=2 then 1 else 0 end) ) *( sum(1) - sum(case when chosenrank <=2 then 1 else 0 end))*.05 [5PctRedirect],
  sum(case when isnull(chosenrank,3)>2 then PotentialSavings else 0 end)/(sum(1) - sum(case when chosenrank <=2 then 1 else 0 end) ) *( sum(1) - sum(case when chosenrank <=2 then 1 else 0 end))*.2 [20PctRedirect]
from results 
--where PotentialSavings <> 0 or PotentialSavings <> NULL
group by TreatmentCOde, Name
having  sum(1) - sum(case when chosenrank <=2 then 1 else 0 end) > 0

-- default method
if @Method is null

with results as (
select distinct memdos, treatmentcode, name, service_from_date, Provider_ID, SHS_ID, Results, LowProviderId, LowPrice, AvgPrice, HiPrice, Incentive, PotentialSavings, case when allowedamount <= lowprice+lowprice*.15 and allowedamount >= Lowprice-lowprice*.15 then 1 else 4 end as ChosenRank from (
  select t.MEMDOS, t.allowedamount, t.TreatmentCode, tc.name, t.Service_From_Date, t.provider_id, s.SearchId SHS_ID,
     (select sum(1) from CAV22_SIM.dbo.vw_ShoppingHistory_1 v where v.SearchId =s.SearchId) Results,
     (select min(ServiceProviderDistinguishedKey) from CAV22_SIM.dbo.vw_ShoppingHistory_1 v where v.SearchId = s.SearchId and Rank = 1) LowProviderId,
     (select min(AverageCost) from CAV22_SIM.dbo.vw_ShoppingHistory_1 v where v.SearchId = s.SearchId) LowPrice,
     (select avg(AverageCost) from CAV22_SIM.dbo.vw_ShoppingHistory_1 v where v.SearchId = s.SearchId) AvgPrice,
     (select max(AverageCost) from CAV22_SIM.dbo.vw_ShoppingHistory_1 v where v.SearchId = s.SearchId) HiPrice,
     (select case when max(IncentiveAmount) is null then 0 else max(IncentiveAmount) end from CAV22_SIM.dbo.vw_ShoppingHistory_1 v where v.SearchId = s.SearchId) Incentive,
     (select avg(AverageCost) from CAV22_SIM.dbo.vw_ShoppingHistory_1 v where v.SearchId = s.SearchId and IncentiveAmount = 0)-(select min(AverageCost) from CAV22_SIM.dbo.vw_ShoppingHistory_1 v where v.SearchId = s.SearchId) - (select case when max(IncentiveAmount) is null then 0 else max(IncentiveAmount) end from CAV22_SIM.dbo.vw_ShoppingHistory_1 v where v.SearchId = s.SearchId) PotentialSavings
  from SimulationReports.dbo.MS_Memdos t inner join CAV22_SIM.dbo.TreatmentCodes tc on t.treatmentcode = tc.code and t.EmployerGroupID= @EmployerGroupID --update with MEMDOS table
   inner join SimulationReports.dbo.MS_URLs s on t.treatmentcode = s.Treatmentcode and left(t.zipcode,5) = s.ZipCode and s.EmployerGroupID= @EmployerGroupID)
   as x) --update with URL table
 
select TreatmentCode, Name, sum(1) Cases, sum(case when chosenrank <=2 then 1 else 0 end) LowCostCases ,   sum(case when chosenrank <=2 then 1.0 else 0 end) / sum(1.0)  PctLowCost,
 sum(1) - sum(case when chosenrank <=2 then 1 else 0 end) CaseswithPotential, (sum(1) - sum(case when chosenrank <=2 then 1 else 0 end))/sum(1.0) PctWithPot,
  sum(case when isnull(chosenrank,3)>2 then PotentialSavings else 0 end) TotalPotentialSavings,
  sum(case when isnull(chosenrank,3)>2 then PotentialSavings else 0 end)/(sum(1) - sum(case when chosenrank <=2 then 1 else 0 end) ) PotSavPerCase,
  sum(case when isnull(chosenrank,3)>2 then PotentialSavings else 0 end)/(sum(1) - sum(case when chosenrank <=2 then 1 else 0 end) ) *( sum(1) - sum(case when chosenrank <=2 then 1 else 0 end))*.05 [5PctRedirect],
  sum(case when isnull(chosenrank,3)>2 then PotentialSavings else 0 end)/(sum(1) - sum(case when chosenrank <=2 then 1 else 0 end) ) *( sum(1) - sum(case when chosenrank <=2 then 1 else 0 end))*.2 [20PctRedirect]
from results 
--where PotentialSavings <> 0 or PotentialSavings <> NULL
group by TreatmentCOde, Name
having  sum(1) - sum(case when chosenrank <=2 then 1 else 0 end) > 0


end