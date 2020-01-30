-- use ramcomtdatadb
/********************************************************************************/
/* procedure      cameron_time_inout_insert_sp                                  */
/* description                                                                  */
/********************************************************************************/
/* project        Cameron                                                       */
/* version				                                                        */
/********************************************************************************/
/* referenced                                                                   */
/* tables                                                                       */
/********************************************************************************/
/* development history                                                          */
/********************************************************************************/
/* author         Sirajudeen S                                                  */
/* date           22/6/2016														*/
/********************************************************************************/
/* modification history                                                         */
/********************************************************************************/
/* modified by    Padmavathi M                                                  */
/* date           19/8/2016                                                     */
/* description                                                                  */
/********************************************************************************/

alter procedure cameron_time_inout_insert_sp
	@DriverId			int		=null,
	@DriverName			nvarchar(200) = null,
	@EndAsset			nvarchar(200) =null,
	@EndEventId			int = null,
	@EndGpsTime			Datetime=null,
	@EndLatitude		nvarchar(200)=null,
	@EndLongitude		nvarchar(200) = null,
	@EndOdometer		int = null,
	@EndTotalFuelUsed	int = null,
	@FleetId			int = null,
	@FleetName			nvarchar(300) = null,
	@IsCorrectAnswers	bit = null,
	@LoginId			int = null,
	@LoginTypeListId	int = null,
	@LogoffId			int = null,
	@LogonType			nvarchar(200) = null,
	@LogonTypeId		int,
	@StartAsset			nvarchar(200)=null,
	@StartEventId		int = null,
	@StartGpsTime		Datetime = null,
	@StartLatitude		nvarchar(200) = null,
	@StartLongitude		nvarchar(300) = null,
	@StartOdometer		int = null,
	@StartTotalFuelUsed	int = null,
	@VehicleId			int = null,
	@VehicleName		nvarchar(300)=null,
	@LoginUser			nvarchar(200)=null,
	@Signature			nvarchar(max) = null,
	@FileName			nvarchar(100)	= null
as
begin

if (isnull (@VehicleId,-1)  in (-1,0))
begin
	return
end 
declare @diffmin int 
	select  @diffmin= DATEDIFF(minute, getutcdate(),GETDATE())
	select @diffmin	= isnull ( TimeZoneDif,@diffmin)
	from cameron_fleet_tbl (nolock)
	where fleetid = @fleetid

	


if exists (select  'x' 
			from cameron_drivers_loginlogout (nolock)
			where	LoginId          =   @LoginId
			)
begin
	update cameron_drivers_loginlogout set
	DriverName          =   @DriverName,
	EndAsset          =   @EndAsset,
	EndEventId          =   @EndEventId,
	EndGpsTime          =   @EndGpsTime,
	EndLatitude          =   @EndLatitude,
	EndLongitude          =   @EndLongitude,
	EndOdometer          =   @EndOdometer,
	EndTotalFuelUsed          =   @EndTotalFuelUsed,
	FleetId          =   @FleetId,
	FleetName          =   @FleetName,
	IsCorrectAnswers          =   @IsCorrectAnswers,
	--LoginId          =   @LoginId,
	LoginTypeListId          =   @LoginTypeListId,
	LogoffId          =   @LogoffId,
	LogonType          =   @LogonType,
	LogonTypeId          =   @LogonTypeId,
	StartAsset          =   @StartAsset,
	StartEventId          =   @StartEventId,
	StartGpsTime          =   @StartGpsTime,
	StartLatitude          =   @StartLatitude,
	StartLongitude          =   @StartLongitude,
	StartOdometer          =   @StartOdometer,
	StartTotalFuelUsed      =   @StartTotalFuelUsed,
	VehicleId          =   @VehicleId,
	VehicleName          =   @VehicleName,
	ModifiedBy          =   @LoginUser,
	ModifiedOn          =   GETDATE()--,
	--diffmin				 =@diffmin
	where	LoginId          =   @LoginId
end
else			
begin	
	Insert into cameron_drivers_loginlogout(
		DriverId,			
		DriverName,
		EndAsset,			
		EndEventId,			
		EndGpsTime,			
		EndLatitude,			
		EndLongitude,		
		EndOdometer,			
		EndTotalFuelUsed,
		FleetId			,	
		FleetName		,	
		IsCorrectAnswers,	
		LoginId			,	
		LoginTypeListId	,	
		LogoffId		,	
		LogonType		,	
		LogonTypeId		,	
		StartAsset		,	
		StartEventId	,	
		StartGpsTime	,	
		StartLatitude	,	
		StartLongitude	,	
		StartOdometer	,	
		StartTotalFuelUsed	,
		VehicleId			,
		VehicleName	,
		CreatedBy,
		CreatedOn,
		diffmin
		  
		)
values(
		@DriverId			,
		@DriverName			,
		@EndAsset			,
		@EndEventId			,
		@EndGpsTime			,
		@EndLatitude		,
		@EndLongitude		,
		@EndOdometer		,
		@EndTotalFuelUsed	,
		@FleetId			,
		@FleetName			,
		@IsCorrectAnswers	,
		@LoginId			,
		@LoginTypeListId	,
		@LogoffId			,
		@LogonType			,
		@LogonTypeId		,
		@StartAsset			,
		@StartEventId		,
		@StartGpsTime		,
		@StartLatitude		,
		@StartLongitude		,
		@StartOdometer		,
		@StartTotalFuelUsed	,
		@VehicleId			,
		@VehicleName,
		@LoginUser,
		getdate()		,
		@diffmin
)
end

/*Pre Trip Section - Start*/
if (isnull (@StartGpsTime,'1900-01-01 00:00:00.000') <> '1900-01-01 00:00:00.000' ) and isnull (@StartEventId,-1) <> -1 and @VehicleId <> -1
begin
	if exists (select 'x'
					from	cameron_pre_start_trip_hdr_tbl (nolock)
					--where	startgpstime	= @StartGpsTime
					--and		Driverid		= @Driverid
					--and		vehicleid		= @VehicleId
					--and		Equipmentcode	= @VehicleName
					where	StartEventId	= @StartEventId
					--and		Equipmentcode	= @VehicleName
					)
	begin
		select @LoginUser = @LoginUser
		if isnull (@Signature,'') <> ''
		begin
			update T set 
			T.signature_data = @Signature,
			T.Filename		 = @Filename
			from	cameron_pre_start_trip_hdr_tbl T (nolock)
			where	StartEventId	= @StartEventId
			--and		Equipmentcode	= @VehicleName
		end
	end
	else
	begin						
		insert into cameron_pre_start_trip_hdr_tbl
		(
		guid , 			
		StartGpsTime,	
		Vehicleid,
		Fleetid,		
		Driverid,
		VehicleName,		
		Equipmentcode,
		associationkey,			
		Status	,				
		createdby,		
		createddate,
		diffmin	,
		StartEventId	,
		signature_data ,
		Filename	
		)
		select 
		newid (),
		@StartGpsTime,
		@VehicleId,
		@FleetId,
		@DriverId,
		@VehicleName,
		@VehicleName,
		null,
		'Pending',
		@LoginUser,
		GETDATE(),
		@diffmin,
		@StartEventId,
		@Signature,
		@Filename

	end
	
	insert into cameron_pre_start_trip_hdr_tbl
		(
		guid , 			
		StartGpsTime,	
		Vehicleid,
		Fleetid,		
		Driverid,
		VehicleName,		
		Equipmentcode,	
		associationkey,		
		Status	,				
		createdby,		
		createddate	,
		diffmin	,
		StartEventId
		)
		select 
		newid (),
		@StartGpsTime,
		@VehicleId,
		@FleetId,
		@DriverId,
		@VehicleName,
		assetName,
		AssetUniqueKey,
		'Pending',
		@LoginUser,
		GETDATE(),
		@diffmin,
		@StartEventId
		from cameron_pretrip_Association_tbl T (nolock)
		where isnull (assetName,'') <> ''
		--and		startgpstime	= @StartGpsTime -- performance issue fix
		and		StartEventId	= @StartEventId
		--and		Driverid		= @Driverid
		--and		vehicleid		= @VehicleId
		and not exists ( select 'x'
							from cameron_pre_start_trip_hdr_tbl P(nolock)
							--where	P.StartGpsTime	= T.StartGpsTime
							--and		P.Driverid		= T.driverid
							--and		P.vehicleid		= T.vehicleid
							--and		P.Equipmentcode	= T.assetname
							where	P.StartEventId	= T.StartEventId
							and		P.Equipmentcode	= T.assetname
							)
						
	
	
end



end



