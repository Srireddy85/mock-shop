--Create MEMDOS based on the CPT Lookup and claims loaded


use SimulationReports
go

create procedure sp_MSUpdateMEMDOS
    @ClientID bigint, 
	@EmployerGroupID bigint, 
	@MaxDate date = null
as

begin
    if @MaxDate = null
        set @MaxDate = dateadd(month, -12,(select max(Service_From_Date) from SimulationReports.dbo.MS_Claims where EmployerGroupID = @EmployerGroupID))
    else
        set @MaxDate = cast(@MaxDate as date)
end

delete from SimulationReports.dbo.MS_Memdos where EmployerGroupID = @EmployerGroupID;
insert into SimulationReports.dbo.MS_Memdos (EmployerGroupID, MEMDOS, Member_ID, Member_DOB, Service_From_Date, TreatmentCode, ProcedureName, Provider_Id,  NetworkPrefix, VitalsClientID, Zipcode, allowedamount )
select distinct
       @EmployerGroupID
	 , concat(c.Member_Id, '-', c.Service_From_Date) as MEMDOS
	 , c.Member_ID
	 , c.Member_DOB
	 , c.Service_From_Date
	 , cpt.TreatmentCode
	 , cpt.ProcedureName
	 , p.Provider_ID
	 , c.NetworkPrefix
	 , c.VitalsClientID
	 , c.ZipCode
	 , cost.allowedamount
from (select * from SimulationReports.dbo.MS_Claims where EmployerGroupID = @EmployerGroupID) c
     left join (select member_id, service_from_date, provider_id, zipcode
		          from (select member_id, service_from_date, provider_id, zipcode,
			            ROW_NUMBER() over(partition by member_id, service_from_date order by allowedamount desc) as roworder
			      from
				(select Member_ID, Service_From_Date, Provider_ID, c.ZipCode, sum(cast(AllowedAmount as numeric(10,2))) as allowedamount
				from (select * from SimulationReports.dbo.MS_Claims where EmployerGroupID = @EmployerGroupID) c
				--inner join [CPT to TC] p on c.CPT=p.CPT and p.Client_id = @ClientId
				inner join SimulationReports.dbo.[CPT to TC_Test2] p on c.CPT=p.CPT and p.Client_id = @ClientId
				where EmployerGroupID = @EmployerGroupID
				group by Member_ID, Service_From_Date, Provider_ID, c.ZipCode)
			x)
		t where roworder=1)p on c.Member_ID = p.Member_ID and c.Service_From_Date = p.Service_From_Date
left join (select  member_id, service_from_date, treatmentcode, ProcedureName
		from
			(select member_id, service_from_date, treatmentcode, procedurename,
			ROW_NUMBER() over(partition by member_id, service_from_date order by allowedamount desc) as roworder
			from
				(select Member_ID, Service_From_Date, p.treatmentcode, p.ProcedureName, sum(cast(AllowedAmount as numeric(10,2))) as allowedamount
				from (select * from SimulationReports.dbo.MS_Claims where EmployerGroupID = @EmployerGroupID) c
				--inner join [CPT to TC] p on c.CPT=p.CPT and p.Client_id = @ClientId
				inner join SimulationReports.dbo.[CPT to TC_Test2] p on c.CPT=p.CPT and p.Client_id = @ClientId
				where EmployerGroupID = @EmployerGroupID
				group by Member_ID, Service_From_Date, treatmentcode, p.ProcedureName)
			x)
		t where roworder=1) cpt on c.Member_ID = cpt.Member_ID and c.Service_From_Date = cpt.Service_From_Date
left join (select member_id, service_from_date, sum(allowedamount) as allowedamount from SimulationReports.dbo.MS_Claims where EmployerGroupID = @EmployerGroupID group by Member_ID, Service_From_Date) cost on c.Member_ID = cost.Member_ID and c.Service_From_Date = cost.Service_From_Date
inner join (select distinct Procedure_Id
              from CAV22_SIM.dbo.IncentiveAmounts
			 where IncentiveTier_Id in (select ID
			                              from CAV22_SIM.dbo.incentivetiers
										 where Plan_Id in (select id from CAV22_SIM.dbo.Plans where Client_Id = @ClientId)
										 )
			) incentivized on (case when len(cpt.TreatmentCode) = 5 then concat('9', cpt.TreatmentCode) else cpt.TreatmentCode end) = incentivized.Procedure_Id
where EmployerGroupID = @EmployerGroupID and p.Provider_ID is not null and cpt.treatmentcode is not null and c.Service_From_Date >= @maxdate
order by 3,5;