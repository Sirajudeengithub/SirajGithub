alter procedure cameron_get_Shippoint_lastupdate_info_sp
@LoginUser		nvarchar(200)=null
as
begin
declare @startdate	datetime,
		@fromdate	datetime,
		@todate		datetime,
		@runningno	bigint ,
		@customer	nvarchar(300),
		@isexist	varchar(300)
		
select	@startdate	= '1-1-2017'      
select  @isexist	= 'false'     
select  @runningno	=  isnull(max(runningno),0) 
                   from cameron_Ship_point_logs_tbl (nolock)
                    where process_status ='success'  
       
select @customer = customer 
				from interface_customer_tbl  (nolock)
				where active = 'YES' 			                                        
if @runningno = 0	
	begin
          select @fromdate=@startdate
          select @todate= getdate()
	end
     
else
     begin
     
     select @fromdate=  isnull (todate ,@startdate)
                             from cameron_Ship_point_logs_tbl (nolock)
                             where process_status ='success' 
                             and   runningno = @runningno
                             
          select @todate= getdate()
     end  
            
 
if @customer in ('CAMERON', 'CAMERONUAT') 
begin
	
	if exists ( select 'x'
	from scmdb.dbo.wms_shp_point_hdr ship(nolock), 
						scmdb..wms_shp_point_loc_div_dtl map(nolock),
						interface_category_item_tbl meta (nolock)
				where	ship.wms_shp_pt_id	= map.wms_shp_pt_id
				and     ship.wms_shp_pt_ou	= map.wms_shp_pt_ou
				and		map.wms_shp_pt_type = 'DIV'
				and		wms_shp_pt_code = meta.name
				and     meta.category	= 'MT-DATA SHIP POINT LIST MAPPING'											       
				and isnull(ship.wms_shp_pt_modified_date,isnull(ship.wms_shp_pt_created_date,getdate()))
												between @fromdate and @todate)
	begin
		insert into cameron_Ship_point_logs_tbl
                   (    
                   fromdate ,
                   todate       ,
                   process_date	 
                   )
                   values
                   (
                   @fromdate,
                   @todate,
                   getdate()       
                   )
		 select @runningno = @@identity
		 select distinct @runningno 'runningno',
			external_ref1 'ListName',
			ship.wms_shp_pt_id 'Account',
			wms_shp_pt_desc 'Ship_point_Desc' ,
			--ship.wms_shp_pt_id 'Name',
			ship.wms_shp_pt_desc + ' ('+ship.wms_shp_pt_id+')' 'Name',
			ship.wms_shp_pt_id 'ExternalRef',
			(case when wms_shp_pt_status = 'AC' then 'true' else 'false' end ) as 'Active' ,
			(isnull (wms_shp_pt_address1,'') 
						+ case when wms_shp_pt_address2 = 'x' OR isnull (wms_shp_pt_address2,'') =''
								then ', ' 
								else wms_shp_pt_address2 end)
							as 'AddressLine2',
			wms_shp_pt_zipcode 'PostCode',
			wms_shp_pt_phone1 'PhoneNumber',
			wms_shp_pt_address1 'AddressLine1',
			'' as 'Note',
			isnull (wms_shp_pt_latitude,-1) as 'Latitude',
			isnull(wms_shp_pt_longitude,-1) as 'Longitude' ,
			
			wms_shp_pt_city 'city',
			wms_shp_pt_state 'state',
			wms_shp_pt_country 'country',
			cast (isnull(wms_shp_pt_geo_fence_range,50)as int) 'geo_fence_range',
			isnull (wms_geo_suburb_desc,wms_shp_pt_suburb_code) 'suburb',
			wms_shp_pt_suburb_code 'MapRef'
			from  	scmdb..wms_shp_point_loc_div_dtl map(nolock),
					interface_category_item_tbl meta (nolock),
					scmdb.dbo.wms_shp_point_hdr ship(nolock)
						left outer join
					scmdb..wms_geo_suburb_dtl suburb (nolock)
					on	suburb.wms_geo_suburb_ou		= wms_shp_pt_ou
					and	suburb.wms_geo_suburb_code 	    = wms_shp_pt_suburb_code 
			where	ship.wms_shp_pt_id	= map.wms_shp_pt_id
			and     ship.wms_shp_pt_ou	= map.wms_shp_pt_ou
			and		map.wms_shp_pt_type 	= 'DIV'
			and		meta.name			= wms_shp_pt_code  
			and     meta.category		= 'MT-DATA SHIP POINT LIST MAPPING'	
		 	and		isnull(ship.wms_shp_pt_modified_date,isnull(ship.wms_shp_pt_created_date,getdate()))
											between @fromdate and @todate	 
												
			select @isexist = 'true' 
	end										             
            
end   
if @customer in ('VISY') 
		begin
		if exists ( select 'x'
					from  scmdb.dbo.wms_shp_point_hdr (nolock)
					where isnull(wms_shp_pt_modified_date,isnull(wms_shp_pt_created_date,getdate()))
									between @fromdate and @todate )
		begin									
			select 
			distinct
			@runningno 'runningno',
			'VISY'		'ListName',
			wms_shp_pt_id 'Account',
			wms_shp_pt_desc 'Ship_point_Desc' ,
			wms_shp_pt_desc + ' ('+wms_shp_pt_id+')' 'Name',
			wms_shp_pt_id 'ExternalRef',
			(case when wms_shp_pt_status = 'AC' then 'true' else 'false' end ) as 'Active' ,
			isnull (wms_shp_pt_address1,'') + 
					',' + isnull (wms_shp_pt_address2,'') as 'AddressLine2',
			wms_shp_pt_zipcode 'PostCode',
			wms_shp_pt_phone1 'PhoneNumber',
			wms_shp_pt_address1 'AddressLine1',
			'' as 'Note',
			isnull (wms_shp_pt_latitude,-1) as 'Latitude',
			isnull(wms_shp_pt_longitude,-1) as 'Longitude' ,
			
			wms_shp_pt_city 'city',
			wms_shp_pt_state 'state',
			wms_shp_pt_country 'country',
			cast (isnull(wms_shp_pt_geo_fence_range,50)as int) 'geo_fence_range',
			wms_shp_pt_suburb_code 'suburb',
			wms_shp_pt_suburb_code 'MapRef'
			from scmdb.dbo.wms_shp_point_hdr (nolock)
			where isnull(wms_shp_pt_modified_date,isnull(wms_shp_pt_created_date,getdate()))
											between @fromdate and @todate 
			select @isexist = 'True'
		end									  
end            
if (@isexist = 'false')
begin
	raiserror ('No Requests' ,16,1)
	return
end            
            
end



