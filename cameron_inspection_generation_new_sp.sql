--  exec cameron_inspection_generation_new_sp 'MTDATA'
use ramcomtdatadb
go
alter procedure cameron_inspection_generation_new_sp
@LoginUser		nvarchar(100)
as
begin

declare @golivedate	datetime
declare @diffmin int
select  @diffmin= DATEDIFF(minute, getutcdate(),GETDATE())
		
select @golivedate = phasedate
from cameron_mtdata_goliveon (nolock)
where active = 'YES'
and phase ='WAVE1'

if (@golivedate is null)
begin
	raiserror ('Please update Go Live plan date',16,1)
	return
end
/*
update hdr set 
hdr.status = 'InProcess'
	from RAMCOMTDATADB..cameron_time_pretrip ml (nolock) ,
	cameron_pre_start_trip_hdr_tbl hdr (nolock) 
	where	hdr.StartGpsTime	= ml.StartGpsTime
	and     hdr.DriverId		= ml.DriverId
	and		hdr.VehicleId		= ml.VehicleId
	and		isnull(hdr.status,'Pending')			= 'Pending'
	and     dateadd (minute,@diffmin, hdr.StartGpsTime) > @golivedate
	and		guid in ( select top 100  guid 
							from cameron_pre_start_trip_hdr_tbl T (nolock) 
							where isnull(T.status,'Pending')			= 'Pending' 
							order by  StartGpsTime desc )
	*/

declare  @tmp_inspection table
(
seqno			int identity (1,1),
requestid		nvarchar(300),
logintime		datetime,
equipmentcode	nvarchar(300),
vehicleid		int,
fleetid			int,
StartEventId	bigint
)
begin tran
update T set T.status = 'Initiated'
-- select T.*
from cameron_pre_start_trip_hdr_tbl T  WITH (updlock, readpast)
where StartEventId in (
						select top 100 StartEventId
						from cameron_pre_start_trip_hdr_tbl hdr (nolock) 
						where	 isnull(hdr.status,'Pending')			= 'Pending'
						and		 StartGpsTime > '2019-09-24'
						and		exists 	( 	select 'x'
											from	RAMCOMTDATADB..cameron_time_pretrip ml (nolock)
											where   hdr.StartEventId		= ml.StartEventId
										)
						order by StartGpsTime asc
						)


insert into @tmp_inspection
(
requestid,
Equipmentcode,
logintime,
vehicleid	,
fleetid,
StartEventId
)
select 
guid,
Equipmentcode,
dateadd (minute,@diffmin,startgpstime),

case when associationkey is null then vehicleid else -915 end,
fleetid,
StartEventId
from cameron_pre_start_trip_hdr_tbl (nolock)
where status = 'Initiated'

update  T set  T.status = 'InProcess'
from cameron_pre_start_trip_hdr_tbl T WITH (updlock, readpast)
where status = 'Initiated'
--and     dateadd (minute,@diffmin, StartGpsTime) > @golivedate

commit tran

declare  @tmp_inspection_ml table
(

seqno				int ,
parameter_code		nvarchar(200),
paramter_value		nvarchar(200),
QuestionID			bigint,
Questiondesc		nvarchar(900),
QuestionType		nvarchar(300)	
			
)

declare @gendocnumber_table table
(
iono_in				nvarchar(200),
ERRORNO				nvarchar(200),
FETCHML				nvarchar(200),  
FPROWNO				nvarchar(200),
PLACEHOLDER1		nvarchar(200), 
PLACEHOLDER2		nvarchar(200),  
PLACEHOLDER3		nvarchar(200), 
PLACEHOLDER4		nvarchar(200),  
SUCCESSFLAG			nvarchar(200), 
IOTASKSPFLAGMLT1	nvarchar(200),  
IOTASKSPFLAGMLT2	nvarchar(200),  
PVMOTYPE			nvarchar(200),
PVMOTYPEMLT2		nvarchar(200), 
PVPARAMTYPEMLT1		nvarchar(200),  
PVPARAMTYPEMLT2		nvarchar(200)
)
-- cameron_time_pretrip


declare @itr_count			int ,
		@i					int ,
		@reportdate			datetime,
		@reported_time		nvarchar(40),
		@IO_date			datetime,
		@IO_time			nvarchar(40),
		@IO_desc			nvarchar(1000),
		@Guid				nvarchar(100),
		@workgroupcode		nvarchar(300),
		--@Equipmentcode		nvarchar(300),
		@driverid			bigint,
		@vehicleid			bigint ,
		@requestid			nvarchar(200),
		@parameter_code		nvarchar(200),
		@parameter_value	nvarchar(200),
		@paramter_remarks	nvarchar(500),
		@insp_order_no		nvarchar(200) ,
		@debug				nvarchar(1000),
		@parameterdescription	nvarchar(600),
		@equipmentcode_ml		nvarchar(300),
		@loginTime				datetime , 
		@reportdate_str			varchar(40),
		@reporttime_str			varchar(40)	,
		@reportdate_onlydate	date,
		@vehicleExternalRef		nvarchar(300),			
		@StartEventId			bigint,
		@fleetid				int,
		@update_Equipment_code	nvarchar(300),
		@FileName				nvarchar(200) = ''

	
--select @workgroupcode = 'GCGWG'	


select @workgroupcode = wkg_work_group 
from scmdb..eam_wrkgrp_wkg_work_grp (nolock)
where wkg_category = 'Internal'
and   wkg_status ='A'
	
select @itr_count = count ('x') from @tmp_inspection
select @i =1
while  ( @i <= @itr_count)
begin

select @i 'Row siraj'
		delete from @gendocnumber_table
		begin tran
		begin try
		
		select @equipmentcode_ml = ''
		select	
				@loginTime			= logintime,
				@requestid			= requestid,
				@equipmentcode_ml	= Equipmentcode,
				@vehicleid			= vehicleid,
				@StartEventId		= StartEventId,
				@fleetid			= fleetid,
				@update_Equipment_code = Equipmentcode
									from @tmp_inspection
									where seqno = @i
		
		
		select @vehicleExternalRef = null
		select @vehicleExternalRef = externalref 
		from cameron_vehicle_master (nolock) 
		where id		= @vehicleid
		and	  fleetid	= @fleetid
		and	  Active	= 1

		select @FileName = ''
		select @FileName = filename
		from cameron_pre_start_trip_hdr_tbl (nolock)
		where StartEventId	= @StartEventId
		and	  Equipmentcode	= @update_Equipment_code
		
		if isnull (@vehicleExternalRef,'') <> ''
		begin
			if (@equipmentcode_ml <> @vehicleExternalRef)
			begin
				select @equipmentcode_ml = @vehicleExternalRef
			end			
		end
			
		select @IO_desc = 'Inspection Order Generated for Equipment Code ('+isnull (@equipmentcode_ml,'<No Equipment>')
									 +') Login Time (' + CONVERT(VARCHAR(19), isnull (@loginTime,'(Error Date)'))  +')'		
									
		select @Guid = newid ()
		
		--select @IO_date	= getdate()
		--select @IO_time = cast(@IO_date as time)
		
		select @IO_date	= @logintime
		select @IO_time = cast(@logintime as time)
		
		select @reportdate		= @logintime
		select @reported_time	= cast(@reportdate as time)
		
		select @reportdate_onlydate = @reportdate
		
		select  @reportdate_str = convert(varchar(10), @reportdate, 120)
		select  @reporttime_str = convert (varchar(8),@reported_time)
				
		declare @p33 int
		set @p33=0
		insert into @gendocnumber_table (
			iono_in	,		
			ERRORNO	,		
			FETCHML	,		
			FPROWNO	,		
			PLACEHOLDER1,	
			PLACEHOLDER2,	
			PLACEHOLDER3,	
			PLACEHOLDER4,	
			SUCCESSFLAG	,	
			IOTASKSPFLAGMLT1,
			IOTASKSPFLAGMLT2,
			PVMOTYPE		,
			PVMOTYPEMLT2	,
			PVPARAMTYPEMLT1	,
			PVPARAMTYPEMLT2	
		)
		exec scmdb..ioaddi_sp_sbt_hsub @createdby_in=N'~#~',@createddate_in=N'01/01/1900',@createdtime_in=N'01/01/1900',
		@ctxt_language_in=1,@ctxt_ouinstance_in=N'2',@ctxt_service_in=N'ioaddi_ser_sbt',@ctxt_user_in=@LoginUser,
		@guid_in=@Guid,@iocloseflag_in=N'1',@iodate_in=@IO_date,
		@iodesc_in=@IO_desc,@ioduration_in=-915.00,@iono_in=N'~#~',@ioremarks_in=N'~#~',@iorepby_in=N'~#~',
		@iorepdate_in=@reportdate_onlydate,@ioreptime_in=@reported_time,@ioroutecode_in=N'~#~',@ioschcompdate_in=N'01/01/1900',
		@ioschcomptime_in=N'01/01/1900',@ioschstdate_in=@reportdate_onlydate,@ioschsttime_in=@reported_time,@iostatus_in=N'~#~',
		@iotime_in=@IO_time,@iotypevalue_in=N'~#~',@ioudcvalue_in=N'~#~',@lastmodifiedby_in=N'~#~',
		@lastmodifieddate_in=N'01/01/1900',@lastmodifiedtime_in=N'01/01/1900',@priorityvalue_in=N'~#~',
		@refdoctype_in=N'Insp Order',@workgroupcode_in=@workgroupcode,@M_ErrorID=@p33 output
		select @p33
		

		--exec scmdb..ioaddi_sp_sbt_hsub @createdby_in=N'~#~',@createddate_in=N'01/01/1900',@createdtime_in=N'01/01/1900',
		--@ctxt_language_in=1,@ctxt_ouinstance_in=N'2',@ctxt_service_in=N'ioaddi_ser_sbt',@ctxt_user_in=@LoginUser,
		--@guid_in=@Guid,@iocloseflag_in=N'1',@iodate_in=@IO_date,
		--@iodesc_in=@IO_desc,@ioduration_in=-915.00,@iono_in=N'~#~',@ioremarks_in=N'~#~',@iorepby_in=N'~#~',
		--@iorepdate_in=@reportdate,@ioreptime_in=@reported_time,@ioroutecode_in=N'~#~',@ioschcompdate_in=N'01/01/1900',
		--@ioschcomptime_in=N'01/01/1900',@ioschstdate_in=@reportdate,@ioschsttime_in=@reported_time,@iostatus_in=N'~#~',
		--@iotime_in=@IO_time,@iotypevalue_in=N'~#~',@ioudcvalue_in=N'~#~',@lastmodifiedby_in=N'~#~',
		--@lastmodifieddate_in=N'01/01/1900',@lastmodifiedtime_in=N'01/01/1900',@priorityvalue_in=N'~#~',
		--@refdoctype_in=N'Insp Order',@workgroupcode_in=@workgroupcode,@M_ErrorID=@p33 output
		--select @p33

		if ( isnull (@p33,0) <> 0)
		begin
			raiserror ('Error occured in ioaddi_sp_sbt_hsub sp; Error id  : %d' , 16,1,@p33)
		end
		
		--@reportdate_onlydate
		
		select @insp_order_no = iono_in
				from @gendocnumber_table
		select @insp_order_no '@insp_order_no' 		

		update scmdb..eam_iomain_insp_order_hdr set 
		iomain_io_date = @logintime		
		where iomain_io_code		= @insp_order_no
		and   iomain_io_ouinstance	= 2
		
		delete from @tmp_inspection_ml

		insert into @tmp_inspection_ml
		(
		QuestionID	,
		QuestionType ,
		Questiondesc,
		paramter_value
		)
		select 
		distinct
		ml.QuestionId ,
		'PreTripQuestion',
		ml.QuestionDesc	 ,
		case when ml.Answer = 'Y' then 'YES'
			 when ml.Answer = 'N' then 'NO'
			 else 'NA' end	
		from	cameron_time_pretrip  ml (nolock)  , 
				cameron_pre_start_trip_hdr_tbl hdr (nolock)
		--where	ml.DriverId				= hdr.DriverId
		--and		ml.VehicleId			= hdr.VehicleId
		--and		ml.StartGpsTime			= hdr.StartGpsTime
		--and		hdr.guid				= @requestid
		where	ml.StartEventId			= hdr.StartEventId
		and		hdr.StartEventId		= @StartEventId
		
		--if exists 
		--		(
		--		select 'x'
		--			from cameron_pretrip_Association_tbl (nolock)
		--					cameron_pre_start_trip_hdr_tbl
		
		if exists ( select 'x'
					 from cameron_pre_start_trip_hdr_tbl (nolock)
					 --where	guid				= @requestid
					 --and	associationkey		is null	)
					 where	StartEventId		= @StartEventId
					 and	Equipmentcode		= @update_Equipment_code
					 and	associationkey		is null	)
		 begin
				insert into @tmp_inspection_ml
				(
				QuestionID	,
				QuestionType ,
				Questiondesc,
				paramter_value
				)
				select 
				distinct
				ml.ItemId ,
				'INSPECTION',
				ml.QuestionDesc,
				case when InspectionResult = 1 then 'NO'
					 when InspectionResult = 2 then 'YES'
					 else 'NA' end 
				from cameron_pretrip_inspection_tbl ml (nolock) , 
						cameron_pre_start_trip_hdr_tbl hdr (nolock)
				--where	ml.DriverId								= hdr.DriverId
				--and		ml.VehicleId							= hdr.VehicleId
				--and		ml.StartGpsTime							= hdr.StartGpsTime
				--and		hdr.guid								= @requestid
				--and     isnull(ml.InspectedAssetUniqueKey,0)	= 0 
				--and     ml.InspectionResult						<>0	
				where	ml.StartEventId							= hdr.StartEventId
				and		hdr.StartEventId						= @StartEventId
				--and		hdr.Equipmentcode						= @equipmentcode_ml
				and		Equipmentcode							= @update_Equipment_code
				and     isnull(ml.InspectedAssetUniqueKey,0)	= 0 
				and     ml.InspectionResult						<>0	
		end
		else
		begin
				insert into @tmp_inspection_ml
				(
				QuestionID	,
				QuestionType ,
				Questiondesc,
				paramter_value
				)
				select 
				distinct
				ml.ItemId ,
				'INSPECTION',
				ml.QuestionDesc,
				case when InspectionResult = 1 then 'NO'
					 when InspectionResult = 2 then 'YES'
					 else 'NA' end 
				from cameron_pretrip_inspection_tbl ml (nolock) , 
						cameron_pre_start_trip_hdr_tbl hdr (nolock)
				--where	ml.DriverId								= hdr.DriverId
				--and		ml.VehicleId							= hdr.VehicleId
				--and		ml.StartGpsTime							= hdr.StartGpsTime
				--and		hdr.guid								= @requestid
				--and     isnull(ml.InspectedAssetUniqueKey,0)	= hdr.associationkey 
				--and     ml.InspectionResult						<>0	
				where	ml.StartEventId							= hdr.StartEventId
				and		hdr.StartEventId						= @StartEventId
				--and		hdr.Equipmentcode						= @equipmentcode_ml
				and		Equipmentcode							= @update_Equipment_code
				and     isnull(ml.InspectedAssetUniqueKey,0)	= hdr.associationkey 
				and     ml.InspectionResult						<>0	
		end							

		update T
		set T.Questiondesc = question.Name
		from @tmp_inspection_ml T, cameron_mtdata_question__master question(nolock)
		where ISNULL (Questiondesc,'') =''
		and	  T.QuestionID		= question.ListItemId
		and	  T.QuestionType	= question.QuestionType
		
		
		update T
		set T.parameter_code =  eqpr_parameter
		from @tmp_inspection_ml T,scmdb..Eam_Eqp_eqpr_Eqp_Parameter (nolock)
		where	cast(eqpr_description as nvarchar(80) )
										= cast (T.Questiondesc as nvarchar(80))

										
		declare @reset_sno	int
		select @reset_sno = 0
		update      @tmp_inspection_ml
		set seqno = @reset_sno, @reset_sno = @reset_sno + 1
		--select  * from @tmp_inspection_ml
		--- ML start
		declare @j		int ,
				@j_count int
		select @j =1
		select @j_count = count('x') 
							from @tmp_inspection_ml
		--select  *  from @tmp_inspection_ml					

		while    (@j <= @j_count)
		begin
		
			select @parameter_code = ''
				select	@parameter_code		= parameter_code ,
						@parameter_value	= paramter_value--,
									from @tmp_inspection_ml
									where seqno = @j
									
				select @paramter_remarks		= substring (eqpr_description,0,80),
						@parameterdescription	= substring (eqpr_description,0,60) 
						
						from scmdb..eam_eqp_eqpr_eqp_parameter
						where	eqpr_parameter = @parameter_code	
				--select @paramter_remarks 'siraj'	
									
				declare @p25 int
				set @p25=0
				exec scmdb..IOAddI_Sp_GetCode @ctxt_language_in=1,@ctxt_ouinstance_in=N'2',@ctxt_service_in=N'ioaddi_ser_sbt',@ctxt_user_in=@LoginUser,
				@guid_in=@Guid,@iocloseflag_in=N'1',@iotaskspcodemlt1_in=N'~#~',@iotaskspflagmlt1_io=N'~#~',
				@modeflag_in=N'I',@pvinsppointmlt_in=N'~#~',@pvmocodemlt_in=@equipmentcode_ml,@pvmotypemlt_in=N'EQUIPMENT',@pvmotypemlt1_in=N'E',
				@pvparammlt_in=@parameter_code,@pvrepdatemlt_in=@reportdate_str,@pvreptimemlt_in=N'01/01/1900',@fprowno_io=@j,@iorepdate_in=@reportdate_onlydate,
				@ioreptime_in=@reported_time,@iotaskspflagmlt2_io=N'~#~',@pvmotype_io=N'~#~',@pvmotypemlt2_io=N'~#~',@pvparamtypemlt1_io=N'~#~',
				@pvparamtypemlt2_io=N'~#~',@M_ErrorID=@p25 output
				select @p25
				
				select @debug =  ' Equipment code : '  + isnull (@equipmentcode_ml,'Empty')+ ' ; parameter_code = ' + isnull(@parameter_code,'Empty') + ' ; '
				if ( isnull (@p25,0) <> 0)
				begin
					raiserror ('Error occured in IOAddI_Sp_GetCode sp; Error id  : %d' , 16,1,@p25)
				end
				
				
				select  'siraj debug 1'

				declare @p65 int
				set @p65=NULL
				exec scmdb..ioaddi_sp_sbtgrid @createdby_in=N'~#~',@createddate_in=N'01/01/1900',@createdtime_in=N'01/01/1900',@ctxt_language_in=1,
				@ctxt_ouinstance_in=N'2',@ctxt_service_in=N'ioaddi_ser_sbt',@ctxt_user_in=@LoginUser,@guid_in=@Guid,
				@iocloseflag_in=N'1',@ioconfirmynmlt_in=N'~#~',@iodate_in=@IO_date,@iodesc_in=@IO_desc,@ioduration_in=-915.00,@iono_in=@insp_order_no,
				@ioremarks_in=N'~#~',@iorepby_in=N'~#~',@iorepdate_in=@reportdate_onlydate,@ioreptime_in=@reported_time,@ioroutecode_in=N'~#~',@ioschcompdate_in=N'01/01/1900',
				@ioschcomptime_in=N'01/01/1900',@ioschstdate_in=@reportdate_onlydate,@ioschsttime_in=@reported_time,@iospltoolcodemlt_in=N'~#~',@iostatus_in=N'~#~',
				@iotaskspcodemlt1_in=N'~#~',@iotaskspflagmlt1_io=N'~#~',@iotime_in=@IO_time,@iotypevalue_in=N'~#~',@ioudcvalue_in=N'~#~',@lastmodifiedby_in=N'~#~',
				@lastmodifieddate_in=N'01/01/1900',@lastmodifiedtime_in=N'01/01/1900',@modeflag_in=N'I',@priorityvalue_in=N'~#~',@pvalertlevelmlt_in=N'~#~',
				@pvinsppointmlt_in=N'~#~',@pvmocodemlt_in=@equipmentcode_ml,@pvmodescmlt_in=N'~#~',@pvmotypemlt_in=N'EQUIPMENT',@pvmotypemlt1_in=N'E',@pvparammlt_in=@parameter_code,
				@pvparamtypemlt_in=N'~#~',@pvparamuommlt_in=N'~#~',@pvparamvaluemlt_in=@parameter_value,@pvremarksmlt_in=@paramter_remarks,@pvrepbymlt_in=N'~#~',@pvrepdatemlt_in=@reportdate_str,
				@pvreptimemlt_in=N'01/01/1900',@refdoctype_in=N'Insp Order',@workgroupcode_in=@workgroupcode,@errorno_io=0,@fetchml_io=0,@fprowno_io=@j,@placeholder1_io=N'~#~',
				@placeholder2_io=N'~#~',@placeholder3_io=N'~#~',@placeholder4_io=N'~#~',@successflag_io=0,@iotaskspflagmlt2_io=N'~#~',@pvmotype_io=N'E',
				@pvmotypemlt2_io=N'EQUIPMENT',@pvparamtypemlt1_io=N'A',@pvparamtypemlt2_io=N'Attribute', @parameterdescription =@parameterdescription, @M_ErrorID=@p65 output
				select @p65
				select  'siraj debug 2'
				if  (isnull (@p65,0)= 14290)
				begin
					raiserror ('Error occured in ioaddi_sp_sbtgrid sp; Parameter code does not exists' , 16,1)
				end
				if ( isnull (@p65,0) <> 0)
				begin
					raiserror ('Error occured in ioaddi_sp_sbtgrid sp; Error id  : %d' , 16,1,@p65)
				end
				--select 'debug 1'
				set @p65=0
				exec scmdb..int_pv_sp_closeio @ctxt_language=1,@ctxt_ouinstance=N'2',@ctxt_service=N'Int_Pv_Ser_CloseIO',@ctxt_user=@LoginUser,
				@iono=@insp_order_no,@rowno=2,@motype=N'E',@pvmocode=@equipmentcode_ml,@pvparam=@parameter_code,@pvinsppoint=N'~#~',@pvparamvalue=@parameter_value,
				@pvrepdate=@reportdate_onlydate,@pvreptime=@reported_time,@pvrepby=N'~#~',@pvremarks=N'~#~',@M_ErrorID=@p65 output
				if ( isnull (@p65,0) <> 0)
				begin
					raiserror ('Error occured in int_pv_sp_closeio sp; Error id  : %d' , 16,1,@p65)
				end
				--select 'debug 2' , @reportdate_str '@reportdate_str' , @reporttime_str '@reporttime_str'
				set @p65=0
				exec scmdb..Prm_Gen_TrgWoWr_Sp1 @ctxt_ouinstance_in=N'2',@ctxt_language_in=1,@ctxt_service_in=N'Prm_Gen_TrgWoWr1_Ser',
				@ctxt_user_in=@LoginUser,@pvmotype_io=N'E',@pvmocode_io=@equipmentcode_ml,@pvinsppoint_io=N'~#~',@pvparammlt_io=@parameter_code,
				@pvparamvalue_io=@parameter_value,@pvrepdatemlt_in=@reportdate_str,@pvreptimemlt_in=@reporttime_str,@M_ErrorID=@p65 output
				if ( isnull (@p65,0) <> 0)
				begin
					raiserror ('Error occured in Prm_Gen_TrgWoWr_Sp1 sp; Error id  : %d' , 16,1,@p65)
				end
				--select 'debug 3'
				select  'siraj debug 3'
				set @p65=0
				exec scmdb..Prm_Gen_TrgWoWr_Sp2 @ctxt_ouinstance_in=N'2',@ctxt_language_in=1,@ctxt_service_in=N'Prm_Gen_TrgWoWr1_Ser',
				@ctxt_user_in=@LoginUser,@pvmotype_in=N'E',@pvmocode_in=@equipmentcode_ml,@pvinsppoint_in=N'~#~',@pvparammlt_in=@parameter_code,
				@pvparamvalue_in=@parameter_value,@wowrno_in=N'',@trgactionmlt_in=N'',@pvrepdatemlt_in=@reportdate_onlydate,@pvreptimemlt_in=@reported_time,
				@pvalertlevelmlt_in=N'',@upabnorlflag_in=N'',@M_ErrorID=@p65 output
				
				if ( isnull (@p65,0) <> 0)
				begin
					raiserror ('Error occured in Prm_Gen_TrgWoWr_Sp2 sp; Error id  : %d' , 16,1,@p65)
				end
			

				select @j = @j +1
		end
--- ML End

		declare @p41 int
		set @p41=0
		exec scmdb..ioaddi_sp_sbthdrck @createdby_in=N'~#~',@createddate_in=N'01/01/1900',@createdtime_in=N'01/01/1900',@ctxt_language_in=1,@ctxt_ouinstance_in=N'2',
		@ctxt_service_in=N'ioaddi_ser_sbt',@ctxt_user_in=N'RAMCOUSER',@guid_in=@Guid,@iocloseflag_in=N'1',@iodate_in=@IO_date,
		@iodesc_in=@IO_desc,@ioduration_in=-915.00,@iono_in=@insp_order_no,@ioremarks_in=N'~#~',@iorepby_in=N'~#~',@iorepdate_in=@reportdate_onlydate,
		@ioreptime_in=@reported_time,@ioroutecode_in=N'~#~',@ioschcompdate_in=N'01/01/1900',@ioschcomptime_in=N'01/01/1900',@ioschstdate_in=@reportdate_onlydate,
		@ioschsttime_in=@reported_time,@iostatus_in=N'~#~',@iotime_in=@IO_time,@iotypevalue_in=N'~#~',@ioudcvalue_in=N'~#~',@lastmodifiedby_in=N'~#~',
		@lastmodifieddate_in=N'01/01/1900',@lastmodifiedtime_in=N'01/01/1900',@priorityvalue_in=N'~#~',@refdoctype_in=N'Insp Order',@workgroupcode_in=@workgroupcode,
		@errorno_io=0,@fetchml_io=0,@fprowno_io=2,@placeholder1_io=N'~#~',@placeholder2_io=N'~#~',@placeholder3_io=N'~#~',@placeholder4_io=N'~#~',@successflag_io=0,
		@M_ErrorID=@p41 output
		select @p41
		if ( isnull (@p41,0) <> 0)
		begin
			raiserror ('Error occured in ioaddi_sp_sbthdrck sp; Error id  : %d' , 16,1,@p41)
		end


		/*
		declare @p14 int
		set @p14=14314
		exec scmdb..ioaddi_sp_sbterrck @ctxt_language_in=1,@ctxt_ouinstance_in=N'2',@ctxt_service_in=N'ioaddi_ser_sbt',@ctxt_user_in=N'RAMCOUSER',@errorno_in=0,
		@fetchml_in=0,@fprowno_in=2,@placeholder1_in=N'~#~',@placeholder2_in=N'~#~',@placeholder3_in=N'~#~',@placeholder4_in=N'~#~',@successflag_in=0,
		@iono_in=@insp_order_no,@M_ErrorID=@p14 output
		select @p14
		if ( isnull (@p14,0) <> 0)
		begin
			raiserror ('Error occured in ioaddi_sp_sbterrck sp; Error id  : %d' , 16,1,@p14)
		end
		*/

		declare @p91 int
		set @p91=0
		exec scmdb..ioaddi_sp_sbthref @ctxt_language_in=1,@ctxt_ouinstance_in=N'2',@ctxt_service_in=N'ioaddi_ser_sbt',@ctxt_user_in=N'RAMCOUSER',@createdby_io=N'~#~',
		@createddate_io=N'01/01/1900',@createdtime_io=N'01/01/1900',@guid_io=@Guid,@iocloseflag_io=N'0',
		@iodate_io=@IO_date,@iodesc_io=@IO_desc,@ioduration_io=-915.00,@iono_io=@insp_order_no,@ioremarks_io=N'~#~',
		@iorepby_io=N'~#~',@iorepdate_io=@reportdate_onlydate,@ioreptime_io=@reported_time,@ioroutecode_io=N'~#~',@ioschcompdate_io=N'01/01/1900',
		@ioschcomptime_io=N'01/01/1900',@ioschstdate_io=@reportdate_onlydate,@ioschsttime_io=@reported_time,@iostatus_io=N'~#~',@iotime_io=@IO_time,
		@iotypevalue_io=N'~#~',@ioudcvalue_io=N'~#~',@lastmodifiedby_io=N'~#~',@lastmodifieddate_io=N'01/01/1900',@lastmodifiedtime_io=N'01/01/1900',
		@priorityvalue_io=N'~#~',@refdoctype_io=N'Insp Order',@workgroupcode_io=N'GCGWG',@M_ErrorID=@p91 output
		select @p91
		if ( isnull (@p91,0) <> 0)
		begin
			raiserror ('Error occured in ioaddi_sp_sbthref sp; Error id  : %d' , 16,1,@p91)
		end
		declare @p92 int
		set @p92=0
		exec scmdb..ioaddi_sp_sbtgrido @createdby=N'RAMCOUSER',@createddate=@IO_date,@createdtime=@IO_time,@ctxt_language=1,
		@ctxt_ouinstance=N'2',@ctxt_service=N'ioaddi_ser_sbt',@ctxt_user=@LoginUser,@guid=@Guid,
		@iocloseflag=N'0',@iodate=@IO_date,@iodesc=@IO_desc,@ioduration=-915.00,@iono=@insp_order_no,@ioremarks=N'',
		@iorepby=N'',@iorepdate=@reportdate_onlydate,@ioreptime=@reported_time,@ioroutecode=N'',@ioschcompdate=N'',@ioschcomptime=N'',@ioschstdate=@reportdate_onlydate,
		@ioschsttime=@reported_time,@iostatus=N'FRESH',@iotime=@IO_time,@iotypevalue=N'',@ioudcvalue=N'',@lastmodifiedby=@LoginUser,
		@lastmodifieddate=@IO_date,@lastmodifiedtime=@IO_time,@priorityvalue=N'',@refdoctype=N'Insp Order',@workgroupcode=@workgroupcode,@M_ErrorID=@p92 output
		select @p33
		if ( isnull (@p33,0) <> 0)
		begin
			raiserror ('Error occured in ioaddi_sp_sbtgrido sp; Error id  : %d' , 16,1,@p92)
		end
		
		if isnull (@FileName,'') <> ''
		begin 
				if exists ( select 'x'
							from scmdb..Not_Notes_AttachDoc (nolock)
							where	tran_no		= @insp_order_no
							and		tran_ou		= 2
							and		tran_type	= 'EAM_IO'
							and		Sequence_no	= 1
							)
				begin
					select @insp_order_no = @insp_order_no
				end
				else
				begin				
					insert into scmdb..Not_Notes_AttachDoc
							(
							Sequence_no,
							tran_no,
							tran_ou,
							tran_type,
							notes_compkey,
							doc_attach_compkey,
							line_entity,
							attach_file,
							Attached_on,
							timestamp,
							line_no
							)
					select			1,
									  @insp_order_no,
									  2,
									 'EAM_IO', 
									 @insp_order_no+' ~ 2 ~ EAM_IO',
									 'EAM_IO_'+@insp_order_no+'_2_Notes',
									 'DOC',
									 @FileName,
									 getdate(),
									 1,
									 0
			end	
		end		
		



		commit
		update T set T.DocumentNo=@insp_order_no , T.Error_msg = null , T.Status ='SUCCESS'
		from cameron_pre_start_trip_hdr_tbl T (nolock)
		--where	guid = @requestid
		where StartEventId		= @StartEventId
		--and	  Equipmentcode		= @equipmentcode_ml
		and	  Equipmentcode		= @update_Equipment_code
		
		end try
		begin catch
			rollback
			select @debug = isnull(@debug,'') + ' :- ' +ERROR_MESSAGE ()
			
			update T set T.DocumentNo=null , T.Error_msg = @debug , T.Status ='FAILED'
			from cameron_pre_start_trip_hdr_tbl T (nolock)
			--where	guid = @requestid
			where StartEventId		= @StartEventId
			--and	  Equipmentcode		= @equipmentcode_ml
			and	  Equipmentcode		= @update_Equipment_code
				
			select @debug '@debug'
			
		end catch 		
		select @i = @i+1	
	end
end



