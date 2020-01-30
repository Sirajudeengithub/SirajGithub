alter procedure cameron_time_pretrip_association_insert_sp
@DriverId					bigint = null,
@DriverName					nvarchar(200) = null,
@VehicleId					bigint = null,
@VehicleName					nvarchar(200) = null,
@StartEventId				bigint = null,
@StartGpsTime				datetime = null,
@AssetUniqueKey				bigint = null,
@AssociationObject			nvarchar(300) = null,
@AssociationType			nvarchar(300) = null,
@AssociationTime			datetime = null,
@InsertedTime				datetime = null,
@Latitude					nvarchar(200) = null,
@Longitude					nvarchar(200) = null,
@MasterFleetId				int = null,
@MasterVehicleId				bigint = null,
@SlaveFleetId				bigint = null,	
@SlaveVehicleId				bigint = null,
@UserId						int = null,
@assetName					nvarchar(300) = null,
@LoginUser					nvarchar(200) = null,
@TripId						bigint = null,
@TripItemId					bigint = null,
@EndEventId					bigint = null,
@EndGpsTime					datetime = null
as
begin

-- getcolumn_sp 'cameron_pretrip_association_tbl'

	if @StartGpsTime is not null
	begin
		if exists 
				(
				select 'x' 
					from cameron_pretrip_association_tbl (nolock)
					--where StartGpsTime	= @StartGpsTime
					--and   StartEventId	= @StartEventId 
					--and   DriverId		= @DriverId	
					--and   VehicleId		= @VehicleId
					--and   AssetUniqueKey= @AssetUniqueKey
					where  StartEventId	= @StartEventId 
					and    AssetUniqueKey= @AssetUniqueKey
				)
				begin
				update T set 
				T.DriverId  = @DriverId,
				T.DriverName  = @DriverName,
				T.VehicleId  = @VehicleId,
				T.VehicleName  = @VehicleName,
				--T.StartEventId  = @StartEventId,
				T.StartGpsTime  = @StartGpsTime,
				--T.AssetUniqueKey  = @AssetUniqueKey,
				T.AssociationObject  = @AssociationObject,
				T.AssociationTime  = @AssociationTime,
				T.InsertedTime  = @InsertedTime,
				T.Latitude  = @Latitude,
				T.Longitude  = @Longitude,
				T.MasterFleetId  = @MasterFleetId,
				T.MasterVehicleId  = @MasterVehicleId,
				T.SlaveFleetId  = @SlaveFleetId,
				T.SlaveVehicleId  = @SlaveVehicleId,
				T.UserId  = @UserId,
				T.assetName  = @assetName,
				T.modifiedby  = @loginuser,
				T.modifieddate  = getdate()
				from cameron_pretrip_association_tbl T (nolock)
					--where StartGpsTime	= @StartGpsTime
					--and   StartEventId	= @StartEventId 
					--and   DriverId		= @DriverId	
					--and   VehicleId		= @VehicleId
					--and   AssetUniqueKey= @AssetUniqueKey 
					where  StartEventId	= @StartEventId 
					and    AssetUniqueKey= @AssetUniqueKey
				end
				else
				begin
				insert into cameron_pretrip_association_tbl
				(
				DriverId,
				DriverName,
				VehicleId,
				VehicleName,
				StartEventId,
				StartGpsTime,
				AssetUniqueKey,
				AssociationObject,
				AssociationTime,
				InsertedTime,
				Latitude,
				Longitude,
				MasterFleetId,
				MasterVehicleId,
				SlaveFleetId,
				SlaveVehicleId,
				UserId,
				assetName,
				createdby,
				createddate
				)
				values 
				(
				@DriverId,
				@DriverName,
				@VehicleId,
				@VehicleName,
				@StartEventId,
				@StartGpsTime,
				@AssetUniqueKey,
				@AssociationObject,
				@AssociationTime,
				@InsertedTime,
				@Latitude,
				@Longitude,
				@MasterFleetId,
				@MasterVehicleId,
				@SlaveFleetId,
				@SlaveVehicleId,
				@UserId,
				@assetName,
				@LoginUser,
				GETDATE()
				)
			end
	end
end


