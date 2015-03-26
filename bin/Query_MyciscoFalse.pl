go 
use itf

delete from dbo.MyciscoFalse

declare @Db datetime, @Da datetime
set @Db = convert(datetime, '20070923', 112);
set @Da = convert(datetime, '20070924', 112);

insert into dbo.MyciscoFalse
select bte.barcode, pgm.ASSEMBLY_REVISION, eve.FALSE_CALL_COMP_COUNT, bte.end_date_time  from board_test as bte
join Repair_event as eve on eve.BOARD_TEST_ID = bte.BOARD_TEST_ID
join test_program as pgm on bte.TEST_PROGRAM_ID = pgm.TEST_PROGRAM_ID
where convert(datetime, bte.end_date_time, 112) >= @Db and convert(datetime, bte.end_date_time, 112) <= @Da and RTRIM(bte.barcode) like '[Ff][Dd][Oo]%'
group by bte.barcode, pgm.ASSEMBLY_REVISION, eve.FALSE_CALL_COMP_COUNT, bte.end_date_time
order by bte.barcode asc
go
