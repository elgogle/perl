go 
use itf

delete from dbo.Mycisco

declare @Db datetime, @Da datetime
set @Db = convert(datetime, '20070923', 112);
set @Da = convert(datetime, '20070924', 112);

insert into dbo.Mycisco 
select bte.barcode , pgm.ASSEMBLY_REVISION , aoi.ref_des, err.name , rep.display_name , bte.end_date_time from board_test as bte
join aoi_test as aoi on bte.BOARD_TEST_ID = aoi.BOARD_TEST_ID
join repair_event as eve on bte.BOARD_TEST_ID = eve.BOARD_TEST_ID
join error_type as err on err.ERROR_TYPE_ID = aoi.ERROR_TYPE_ID
join repair_type as rep on aoi.repair_status = rep.repair_type_id
join test_program as pgm on bte.TEST_PROGRAM_ID = pgm.TEST_PROGRAM_ID
where convert(datetime, bte.end_date_time, 112) >= @Db and convert(datetime, bte.end_date_time, 112) < @Da and RTRIM(bte.barcode) like '[Ff][Dd][Oo]%'
group by bte.barcode, pgm.ASSEMBLY_REVISION, aoi.REF_DES, err.name, rep.display_name, bte.end_date_time
order by bte.barcode asc
go