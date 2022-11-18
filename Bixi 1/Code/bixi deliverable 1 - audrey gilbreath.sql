##########################
### Bixi deliverable 1 ###
##########################

-- -- -- -- -- PART 1 -- -- -- -- -- 
-- trips table
select *
from trips;

-- stations table
select *
from stations;

## 1.1) number of trips in 2016 
SELECT count(*)
FROM trips
where date_format(start_date, '%Y') = '2016';
-- 3917401 trips in 2016

## 1.2) number of trips in 2017 
select count(*)
from trips
where date_format(start_date, '%Y') = '2017';
-- 4666765 trips in 2016

## 1.3) number of trips in 2016 by month 
select count(*), date_format(start_date, '%M') as 'month'
from trips
where date_format(start_date, '%Y') = '2016'
group by date_format(start_date, '%M');

## 1.4) number of trips in 2017 by month 
select count(*), date_format(start_date, '%M') as 'month'
from trips
where date_format(start_date, '%Y') = '2017'
group by date_format(start_date, '%M');

## 1.5) The average number of trips a day for each year-month combination in the dataset.
-- plan:
-- step 1: sum of trips each month
-- step 2: query the number of days in each month
-- step 3: join
-- step 4: divide step 1 by numner of days in each month

-- step 1: sum of trips each month
select count(*) as monthTrips, date_format(start_date, "%M %Y") as monthYear
from trips 
group by monthYear;

-- step 2: number of days in each month
select distinct date_format(start_date, "%M %Y") as monthYear, DAY(LAST_DAY(start_date)) as daysInMonth 
from trips;

-- step 3: second attempt: join >> aggregated query first
select count(*) as monthTrips, -- 2nd query gives how many trip in each month-year and the number of days in each month-year
		t.daysInMonth, 
		monthYear
from  ( 
		select date_format(start_date, "%M %Y") as monthYear, -- 1st query gives the number of days in each month-year
				DAY(LAST_DAY(start_date)) as daysInMonth
		from trips) as t
group by monthYear, t.daysInMonth;

-- step 4:  divide monthTrips by daysInYear >> join
select count(*) as monthTrips, 
		t.daysInMonth, 
		monthYear,
        count(*)/t.daysInMonth as avgMonthTrip
from  ( 
		select date_format(start_date, "%M %Y") as monthYear, 
				DAY(LAST_DAY(start_date)) as daysInMonth
		from trips) as t
group by monthYear, t.daysInMonth;

## 1.6) 
drop table if exists working_table1;
create table working_table1 as
select count(*) as monthTrips, 
		t.daysInMonth, 
		monthYear,
        count(*)/t.daysInMonth as avgMonthTrip
from  ( 
		select date_format(start_date, "%M %Y") as monthYear, 
				DAY(LAST_DAY(start_date)) as daysInMonth
		from trips) as t
group by monthYear, t.daysInMonth;

-- -- -- -- -- PART 2 -- -- -- -- -- 
## 2.1) total number of trips in 2017 by membership status
select count(*) as numTrips, date_format(start_date, "%Y") as theYear, is_member
from trips
where date_format(start_date, "%Y") = 2017
group by theYear, is_member;

## 2.2) 
-- To analyze how membership behavior varies month to month in 2017 I will use the total number of trips each month as the denominator. This will shed light on how membership status flucuates as the seasons change, when people are starting or dropping their membership. Such as if there are more non-members riding in April than members but more members riding in May than non-members. Using the number of member trips in 2017 as the denominator would tell us which month has fewer trips, which we already know just from counting the number of trips each month. Furthermore, to analyze how membership status flucuates from month to month we need to campare the number of members to the number of members and non-members for each month. Using the total number of member trips for 2017 as the denominator does not meet the objective since it compares members to members.
select date_format(start_date, "%M %Y") as monthYear,   
		count(    
			case when date_format(start_date, "%Y") = 2017 and is_member = 1 then 1 end) as memTrips,   
		count(    
			case when date_format(start_date, "%Y") = 2017 then 1 end) as monthTrips,
		count(case when date_format(start_date, "%Y") = 2017 and is_member = 1 then 1 end)/count(case when date_format(start_date, "%Y") = 2017 then 1 end) * 100 as memTripPercentage -- memTrips / monthTrips
from trips 
where date_format(start_date, "%Y") = 2017 
group by monthYear 
order by monthYear asc;

-- -- -- -- -- PART 3 -- -- -- -- -- 
## 3.1 peak demand by month
select date_format(start_date, "%M") as month,
		(count(case when date_format(start_date, "%Y") = 2016 then 1 end)
		+ count(case when date_format(start_date, "%Y") = 2017 then 1 end)) as monthlySum
from trips
group by month
order by monthlySum desc;
-- Gratest to least:  July, August, June, September, May, October, April, November

## 3.2 
select date_format(start_date, "%M") as month,   
		count(case when is_member = 1 then 1 end) as memTrips,   
		count(is_member) as monthTrips,
		count(case when is_member = 1 then 1 end)/count(is_member) * 100 as memTripPercentage -- memTrips / monthTrips
from trips 
group by month
order by month;
-- Reccomend June-Augest since those months have the highest amount of trips but the least trips by active members. Higher numbers of non-members are riding in the summer than any other time of the year by 5+ percentage points.

 -- -- -- -- -- PART 4 -- -- -- -- -- 
## 4.1 top 5 starting stations using join
select count(t.id) as trips, s.name
from stations as s
left join trips as t
	on s.code = t.start_station_code
group by s.name
order by trips desc
limit 5;
-- Mackay / de Maisonneuve, Métro Mont-Royal (Rivard / du Mont-Royal), Métro Place-des-Arts (de Maisonneuve / de Bleury), Métro Laurier (Rivard / Laurier), Métro Peel (de Maisonneuve / Stanley)
-- duration: 4.563 sec / 0.000045 sec

## 4.2 top 5 starting stations using subquery
select t.trips, s.name
from stations as s
left join (
			select count(*) as trips, start_station_code
            from trips as a
            group by start_station_code) as t
on t.start_station_code = s.code
order by trips desc
limit 5;
-- duration: 0.902 sec / 0.000024 sec
-- Why do 4.1 and 4.2 have different run times? Because the filtering and aggregation the subquery in 4.2 happens first, giving the query a small dataset to act on. In 4.1, the two tables join first resulting in a larger dataset, then the filtering and aggregation happens on the now larger dataset.

-- -- -- -- -- PART 5 -- -- -- -- -- 
## 5.1: distribution of starts and ends throughout day at Mackay / de Maisonneuve
select t.trips, s.name, s.code -- station code for Mackay: 6100
from stations as s
left join (
			select count(*) as trips, start_station_code
            from trips as a
            group by start_station_code) as t
on t.start_station_code = s.code
order by trips desc
limit 5; 

select s.timeOfDay, s.startCount, e.endCount -- -- start and end time classifications & counts for Mackay
from 
		(SELECT count(case when start_station_code = 6100 then 1 end) startCount,
				CASE
					WHEN HOUR(start_date) BETWEEN 7 AND 11 THEN "morning"
					WHEN HOUR(start_date) BETWEEN 12 AND 16 THEN "afternoon"
					WHEN HOUR(start_date) BETWEEN 17 AND 21 THEN "evening"
					ELSE "night"
					END AS timeOfDay			
		from trips
        group by timeOfDay) as s
 inner join (
				select 
					count(case when end_station_code = 6100 then 1 end) as endCount,    
					case
						WHEN HOUR(end_date) BETWEEN 7 AND 11 THEN "morning"
						WHEN HOUR(end_date) BETWEEN 12 AND 16 THEN "afternoon"
						WHEN HOUR(end_date) BETWEEN 17 AND 21 THEN "evening"
						ELSE "night"
						END AS timeOfDay
				from trips 
		group by timeOfDay) as e
	on s.timeOfDay = e.timeOfDay;

##5.2:
-- There are more people commuting to Mackay in the morning than leaving
-- There are more people leaving Mackey in the eveing and at night than coming to Mackay at those times
-- -- This suggests that people are commuting to their work/school that's in Mackay in the morning and leaving Mackay when their day is over
-- -- -- possible promotion: get schools and businesses to buy bulk memberships for their employees at a discountd price and/or partner with schools and businesses to give their student/employees can purchase a membership as a discounted price.

-- -- -- -- -- PART 6 -- -- -- -- -- 
-- stations with 10% of trips being roundtrips

## 6.1: number of start trips per stationn
select count(*) as startTrips, start_station_code
from trips
group by start_station_code; 

## 6.2: number of round trips per station
select count(*) roundTrips, start_station_code, end_station_code
from trips
where start_station_code = end_station_code
group by start_station_code, end_station_code;

## 6.3: ratio of roundtrips to start trips per station
select  s.start_station_code, 
    count(case when r.start_station_code = r.end_station_code then 1 end)/s.startTrips*100 as roundTripPercent
from trips as r
inner join (
		select count(*) as startTrips, start_station_code -- subquery for total startTrips per station
        from trips as a
        group by start_station_code) as s
on r.start_station_code = s.start_station_code
group by start_station_code;

## 6.4: filter stations to 500 startTrips minimum and 10% of trips are roundTrips
select s.start_station_code,
		count(case when r.start_station_code = r.end_station_code then 1 end) as roundTrips,
		s.startTrips, 
		count(case when r.start_station_code = r.end_station_code then 1 end)/s.startTrips*100 as roundTripPercent
from trips as r
inner join (
		select count(*) as startTrips, start_station_code -- subquery for total startTrips per station
        from trips as a
        group by start_station_code) as s
	on r.start_station_code = s.start_station_code
where s.startTrips >= 500
group by start_station_code
having count(case when r.start_station_code = r.end_station_code then 1 end)/s.startTrips*100 >= 10;
    
## 6.5: where to expect to find stations with high ratio of round trips
select s.start_station_code, s.name,
		count(case when r.start_station_code = r.end_station_code then 1 end) as roundTrips,   
        s.startTrips,    
        count(case when r.start_station_code = r.end_station_code then 1 end)/s.startTrips*100 as roundTripPercent 
from trips as r 
inner join (   
		select count(*) as startTrips, start_station_code, n.name -- total startTrips per station         
		from trips as a
		inner join (
				select name, code
				from stations) as n
		on a.start_station_code = n.code
		group by start_station_code, n.name) as s 
	on r.start_station_code = s.start_station_code 
where s.startTrips >= 500 
group by start_station_code, s.name
having count(case when r.start_station_code = r.end_station_code then 1 end)/s.startTrips*100 >= 10;
-- metro stations have higher roundtrip ratios because people are using the bikes for their last leg of commute going to work/school or their first leg of commute going home. People usually take the same route to work/school and would there for be using the same metro station consistently.










select  s.start_station_code,   
		count(case when r.start_station_code = r.end_station_code then 1 end) as roundTrips, -- rountTrips per station     
        s.startTrips,     
        count(case when r.start_station_code = r.end_station_code then 1 end)/s.startTrips*100 as ratio 
from trips as r 
inner join (   
		select count(*) as startTrips, start_station_code -- subquery for total startTrips per station         
        from trips as a         
        group by start_station_code) as s 
on r.start_station_code = s.start_station_code 
where count(case when r.start_station_code = r.end_station_code then 1 end)/s.startTrips*100 >= 10
group by start_station_code;








