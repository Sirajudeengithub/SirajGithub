
create clustered index ix_cameron_pre_start_trip_hdr_tbl
 on cameron_pre_start_trip_hdr_tbl(StartEventId, Equipmentcode)
 go
 
create nonclustered index ix2_cameron_pre_start_trip_hdr_tbl
 on cameron_pre_start_trip_hdr_tbl(Status)
 go
 
create nonclustered index ix3_cameron_pre_start_trip_hdr_tbl
 on cameron_pre_start_trip_hdr_tbl(StartGpsTime)

 go

 create clustered index ix_cameron_pretrip_inspection_tbl
on  cameron_pretrip_inspection_tbl (StartEventId, InspectionId, ItemId)

 go

 create clustered index ix_cameron_time_pretrip
on  cameron_time_pretrip (StartEventId, QuestionId)
go

 create clustered index ix_cameron_pretrip_association_tbl
on  cameron_pretrip_association_tbl (StartEventId, AssetUniqueKey)