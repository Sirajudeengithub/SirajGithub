use ramcomtdatadb
go
alter table cameron_pre_start_trip_hdr_tbl
add signature_data	nvarchar(max) ,
	Filename		nvarchar(100)
go

alter table cameron_pre_start_trip_hdr_tbl
add StartEventId bigint