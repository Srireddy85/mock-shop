use SimulationReports
go

create procedure sp_MSCreateURL
    @ClientID bigint, 
	@EmployerGroupID bigint,
	@TestMember nvarchar(50)
as

delete from MS_URLs where EmployerGroupID = @employergroupID

insert into MS_URLS (Treatmentcode, zipcode, [URL], SearchID, OOS, EmployerGroupID, ClientId)
select distinct
       Treatmentcode
	 , left(zipcode,5) as zipcode
	 , concat('http://ncctcostlookup-sim.svcs.mdx.med:8000/api/costs?alphaPrefix='
	         ,Networkprefix
			 ,'&treatmentCategory='
			 ,treatmentcode
			 ,'&city=&state=&zip='
			 ,left(zipcode,5)
			 ,'&searchradius=30&clientId='
			 ,VitalsClientID,'&memberId='
			 ,@TestMember
			 ,'&dateOfBirth=01/01/1990&providerType=F')as [URL]
			 , null as SearchID
			 , 1 as OOS
			 , @EmployerGroupID as EmployerGroupID
			 , @ClientID as ClientId
from MS_MEMDOS
where zipcode <> ''
  and EmployerGroupID = @EmployergroupID 