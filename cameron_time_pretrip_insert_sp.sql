/********************************************************************************/
/* procedure      cameron_time_pretrip_insert_sp                                */
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
/* modified by     Sirajudeen                                               */
/* date            19/8/2016                                                    */
/* description                                                                  */
/********************************************************************************/

alter procedure cameron_time_pretrip_insert_sp
	@DriverId		int =null,
	@DriverName		nvarchar(200)=null,
	@VehicleId		int= null,
	@VehicleName	nvarchar(300)= null,
	@StartEventId	int = null,
	@StartGpsTime	Datetime = null,
	@QuestionId		nvarchar(300)=null,
	@Answer			nvarchar(300)=null,
	@AnswerText		nvarchar(300)=null,
	@CorrectAnswer	varchar(200)=null,
	@LoginUser		nvarchar(200)=null,
	@TripId			bigint = null,
	@TripItemId		bigint = null ,
	@EndEventId		int	= null,
	@EndGpsTime		datetime = null,
	@QuestionDesc	nvarchar(900) = null
	
as
begin

	if @StartGpsTime is not null
	begin
		IF EXISTS (
				select 'x'
				from cameron_time_pretrip ( nolock)
				/*
				where StartGpsTime	= @StartGpsTime
				and   StartEventId	= @StartEventId 
				and   DriverId		= @DriverId	
				and   VehicleId		= @VehicleId
				--and	  EndEventId	= @EndEventId		
				--and   EndGpsTime	= @EndGpsTime
				and   QuestionId	= @QuestionId
				*/
				where  StartEventId	= @StartEventId 
				and   QuestionId	= @QuestionId
		)
		BEGIN
			SELECT @LoginUser = @LoginUser
		END
		ELSE
		BEGIN
		Insert into cameron_time_pretrip(
					DriverId     ,
					DriverName   ,
					VehicleId    ,
					VehicleName  ,
					StartEventId ,
					StartGpsTime ,
					EndEventId		,
					EndGpsTime		,
					QuestionId   ,
					Answer       ,
					AnswerText   ,
					CorrectAnswer,
					TripId	,
					TripItemId	,
					QuestionDesc,
					CreatedBy,
					CreatedOn)
			values(
					@DriverId     ,
					@DriverName   ,
					@VehicleId    ,
					@VehicleName  ,
					@StartEventId ,
					@StartGpsTime ,
					@EndEventId		,
					@EndGpsTime		,
					@QuestionId   ,
					@Answer       ,
					@AnswerText   ,
					@CorrectAnswer ,
					@TripId	,
					@TripItemId	,
					@QuestionDesc,
					@LoginUser	,
					getdate()				
					)
			END		
	end	
end



