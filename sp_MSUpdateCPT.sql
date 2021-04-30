use SimulationReports
go

create procedure sp_MSUpdateCPT @ClientID bigint
as
if (select count(*) from SimulationReports.dbo.[CPT to TC] where Client_id = @ClientId) = 0
insert into SimulationReports.dbo.[CPT to TC] (ProcedureId, ProcedureName, CPT, Client_id, treatmentcode, proc_type)
select a.ProcedureId
     , ProcedureName
	 , CPT
	 , @ClientID
	 , a.treatmentcode
	 , proc_type
from SimulationReports.dbo.[CPT to TC] a
     inner join CAV22_SIM.dbo.ClientTreatmentCodes b
	         on a.treatmentcode = b.TreatmentCode
			and b.Client_ID = @ClientID
where a.Client_id = @ClientID; 