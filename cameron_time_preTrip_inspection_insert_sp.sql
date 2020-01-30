/********************************************************************************/
/* procedure      cameron_time_preTrip_inspection_insert_sp                                */
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
/* date           13/03/2017  													*/
/********************************************************************************/
/* modification history                                                         */
/********************************************************************************/
/* modified by     Sirajudeen                                               */
/* date            13/03/2017                                                    */
/* description                                                                  */
/********************************************************************************/

CREATE procedure cameron_time_preTrip_inspection_insert_sp
@DriverId					bigint		=null,
@DriverName					nvarchar(200)		=null,
@VehicleId					bigint		=null,
@VehicleName				nvarchar(200)		=null,
@StartEventId				bigint		=null,
@StartGpsTime				datetime		=null,
@InspectionId				bigint		=null,
@ItemId						bigint		=null,
@InspectionResult			nvarchar(200)		=null,
@DefectId					bigint		=null,
@AssessedStopWork			nvarchar(200)		=null,
@DefaultStopWork			nvarchar(200)		=null,
@TripId						bigint		=null,
@TripItemId					bigint		=null,
@EndEventId					bigint		=null,
@EndGpsTime					datetime		=null,
@LoginUser					nvarchar(200)	= null,
@QuestionDesc				nvarchar(900) = null,
@InspectedAssetUniqueKey	int = null,
@InspectedFleetId			int = null,
@InspectedVehicleId			int = null
as
begin

	if @StartGpsTime is not null
	begin
		IF EXISTS (
				select 'x'
				from cameron_pretrip_inspection_tbl ( nolock)
				--where StartGpsTime				= @StartGpsTime
				--and   StartEventId				= @StartEventId 
				--and   DriverId					= @DriverId	
				--and   VehicleId					= @VehicleId
				----and	  EndEventId				= @EndEventId		
				----and   EndGpsTime				= @EndGpsTime
				--and   ItemId					= @ItemId
				--and   InspectionId				= @InspectionId
				--and	  isnull(InspectedAssetUniqueKey,0)   = isnull(@InspectedAssetUniqueKey,0)
				where StartEventId				= @StartEventId 
				and   ItemId					= @ItemId
				and   InspectionId				= @InspectionId

		)
		BEGIN
			update T set
			T.DriverId  = @DriverId,
			T.DriverName  = @DriverName,
			T.VehicleId  = @VehicleId,
			T.VehicleName  = @VehicleName,
			--T.StartEventId  = @StartEventId,
			T.StartGpsTime  = @StartGpsTime,
			--T.InspectionId  = @InspectionId,
			--T.ItemId  = @ItemId,
			T.InspectionResult  = @InspectionResult,
			T.DefectId  = @DefectId,
			T.AssessedStopWork  = @AssessedStopWork,
			T.DefaultStopWork  = @DefaultStopWork,
			T.TripId  = @TripId,
			T.TripItemId  = @TripItemId,
			T.EndEventId  = @EndEventId,
			T.EndGpsTime  = @EndGpsTime,
			T.modifiedby  = @LoginUser,
			T.modifieddate  = getdate(),
			T.QuestionDesc	=@QuestionDesc ,
			T.InspectedAssetUniqueKey	= @InspectedAssetUniqueKey,
			T.InspectedFleetId			= @InspectedFleetId	,
			T.InspectedVehicleId		= @InspectedVehicleId
			from cameron_pretrip_inspection_tbl T( nolock)
			--where StartGpsTime	= @StartGpsTime
			--and   StartEventId	= @StartEventId 
			--and   DriverId		= @DriverId	
			--and   VehicleId		= @VehicleId
			----and	  EndEventId	= @EndEventId		
			----and   EndGpsTime	= @EndGpsTime
			--and   ItemId		= @ItemId
			--and   InspectionId  = @InspectionId
			--and	  isnull(InspectedAssetUniqueKey,0)   = isnull(@InspectedAssetUniqueKey,0)

			where StartEventId				= @StartEventId 
			and   ItemId					= @ItemId
			and   InspectionId				= @InspectionId
		END
		ELSE
		BEGIN
		Insert into cameron_pretrip_inspection_tbl(
					DriverId,
					DriverName,
					VehicleId,
					VehicleName,
					StartEventId,
					StartGpsTime,
					InspectionId,
					ItemId,
					InspectionResult,
					DefectId,
					AssessedStopWork,
					DefaultStopWork,
					TripId,
					TripItemId,
					EndEventId,
					EndGpsTime,
					createdby,
					createddate,
					QuestionDesc,
					InspectedAssetUniqueKey	,
					InspectedFleetId	,
					InspectedVehicleId	
					)
			values(
					@DriverId,
					@DriverName,
					@VehicleId,
					@VehicleName,
					@StartEventId,
					@StartGpsTime,
					@InspectionId,
					@ItemId,
					@InspectionResult,
					@DefectId,
					@AssessedStopWork,
					@DefaultStopWork,
					@TripId,
					@TripItemId,
					@EndEventId,
					@EndGpsTime,
					@LoginUser	,
					getdate()	,
					@QuestionDesc	,
					@InspectedAssetUniqueKey	,
					@InspectedFleetId	,
					@InspectedVehicleId			
					)
			END	
		end		
end



