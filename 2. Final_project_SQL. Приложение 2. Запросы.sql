-- ��������� ������ �� ������ "SQL � ��������� ������". ���������� 2. �������

--������ 1
-- � ����� ������� ������ ������ ���������?

-- ����: ����� ������ � ��������� �� ��������� ��� ������ ���������� ������� count()
-- ��� ���� ������������� � �������� ��, � ������� ���������� ����� 1 ��� ������ having
-- ����� ������������� ��� ���������� �� �������� 


select city, count(airport_name) as total_number_airports
from airports a 
group by city 
having count(airport_name) > 1
order by city;

--������ 2
-- � ����� ���������� ���� �����, ����������� �������� � ������������ ���������� �������? 

--����: ����� �� ���������� ������ (��� �������� ��������� � ����� ����� �������)
--��� ������ ��������� ���������� ������������ �������� ��������� ������� �� ������ ��������� ������
-- ���� ��������� ��� ����������� ��� ������ �����-���� ������� � ���� ����������
--����� ��� ��� ������ ��� ���������, ��� ���� ������ ������������/������������
--� ����� ����� ��������, ����������� ���� ���, ���� ������ � ��������� ��������� � ���������� �� ����� ����������

select  a.airport_name, a.airport_code
from airports a 
where a.airport_code in (
	select f2.arrival_airport
	from  flights f2 
	where aircraft_code =
			(
			select a2.aircraft_code
			from aircrafts a2 
			where a2."range" = (select max(range) from aircrafts)
			) 
						)
order by a.airport_name;

--������ 3
--������� 10 ������ � ������������ �������� �������� ������

--����: ��� ����������� � ������������� ����� ���� ������� ��������� ��������� ��� �����������: ����� �����, 
-- ����� ����������� �� ���������� � ����������, �������� ��� �������� ���������� ����������,
-- �������� ����������� � ��������
-- ����� ������� ��� ������, ��� ��� ������ (NULL) �� ��������, ���������� �� �������� ��������
--������� ������ 10 ��� ������ limit

select flight_no, scheduled_departure, actual_departure, (actual_departure - scheduled_departure) as delay, departure_airport, arrival_airport 
from flights f2 
where (actual_departure - scheduled_departure) is not NULL
order by delay desc 
limit 10;

--������ 4
--���� �� �����, �� ������� �� ���� �������� ���������� ������?
 
--����: ��� ������ ������������ � ������� � ������� ���������, �.�. � ������, ������� � �����������
-- ��������, ����� ����� ������, ��� ����������, ��� ��� ��� ����� Null
--����� ������� ������, ��� NULL � ��������� ���������� � ������� �� ����� ��� � ����� ����� 

select count(*) as without_board_pass
from tickets t3 
left join boarding_passes bp on t3.ticket_no = bp.ticket_no 
where bp.boarding_no is null;

--������ 5
--������� ��������� ����� ��� ������� �����, �� % ��������� � ������ ���������� ���� � ��������.
--�������� ������� � ������������� ������ - ��������� ���������� ���������� ���������� ���������� 
--�� ������� ��������� �� ������ ����. �.�. � ���� ������� ������ ���������� ������������� ����� - ������� 
--������� ��� �������� �� ������� ��������� �� ���� ��� ����� ������ ������ �� ����.


--����: ������ ���� �� ���� �����������: ������ - ������ ������� ���� �� ���������� ������� ��������������� �� ��������
-- ������ - ������ ������ ����� ���� ��� ������ ������ ������� �� �������� ����
--����� ����������� ����������� ��� ������ join- �� � ������������� ������� ������� � select ��� ����������� ���������� �� ��������� � �� ����

select departure_airport, actual_departure, flight_no, aircraft_code, (total_seats - busy_places) as free_places, 
	total_seats, round((1 - busy_places/total_seats::float) * 100) as free_to_total_perst,
	sum(busy_places) over (partition by departure_airport, date_trunc('day', actual_departure) order by actual_departure)
from flights
join (
		select flight_id, count(seat_no) as busy_places from boarding_passes bp group by flight_id
	 ) as one using (flight_id)
join (
		select aircraft_code, count(seat_no) as total_seats from seats s2 group by aircraft_code 
	 ) as two using (aircraft_code);
--------------------------------------------------------------------------------------------------------

--������ 6
--������� ���������� ����������� ��������� �� ����� ��������� �� ������ ����������.

--����: ��� ������ ��� (���) ��������� ���������� �������� �� ������ ������ �������, � ����� 
--� ���������� ��� ������� � ������������� ����� ���� ��������, ����� ������ ������ ���������
-- ���������� �������� � ������ ����� �������� � ����������� �� ������� �����
--��� �������� � ����������� ���������� �� ��������

with cte as (
	select  a.model, count(f.flight_id) as quant_of_flight
	from flights f 
	join aircrafts a on a.aircraft_code = f.aircraft_code 
	group by a.model
			)
select two.model, two. quant_of_flight, round(two. quant_of_flight/ (select sum( quant_of_flight) from cte) * 100, 2) as perst_by_model_to_total
from (
		select model,  quant_of_flight, sum( quant_of_flight) over (order by model) as summa
		from cte
		group by model,  quant_of_flight
		) as two
order by model 


--������ 7
--���� �� ������, � ������� ����� ��������� ������ - ������� �������, ��� ������-������� � ������ ��������?

--����: � ��� (���) ���������� ������ ������������ �������� �� flight_id - ��������, � ������ ��� � ������� ��� ������ ��� ���������� ����� ��� ����� � �������, ������� ����� ����� �������� � ��� ����
--�������� Business �������, ����� �� �������, ���������, ������, ��� ��� ��� ������ ������ ����������� ��� ��������� 
--�� ����� �������, ��� �� ��� ��������� � �����

with cte as (
	select tf.flight_id, amount, a.airport_name, a.city,  fare_conditions, min(amount) over (partition by f.flight_id) as minimum
	from ticket_flights tf 
	join flights f on tf.flight_id = f.flight_id 
	join airports a on f.arrival_airport = a.airport_code
	order by tf.flight_id
)
select flight_id, airport_name, city
from cte
where minimum = amount and fare_conditions = 'Business'
order by flight_id
	

--������ 8
--����� ������ �������� ��� ������ ������?

--����: � ����������������� ������������� �������� ������ ������������ �� ���������� ���������� 
--� �������� ������� � ��������� �������� join ���������� ��� �������� ����� ����
-- � ������ ���� ����������� ������������ ���� ��������� ��� ��������� �������, ������� ����� �� ����
--��������� �������� ���� �� � � � (where), � ����� ��������� (except) �� ��������, ������� ����
--������������� ��� ��������, ������������ � �������

create materialized view my_view_routes as (
	select distinct ai2.city as depart_city,  ai1.city as arriv_city
	from flights fl
	join airports ai1 on ai1.airport_code = fl.arrival_airport 
	join airports ai2 on ai2.airport_code = fl.departure_airport
	order by depart_city
)

select a1.city as A, a2.city as B
from airports a1 cross join airports a2
where a1.city != a2.city
except select arriv_city, depart_city
		from my_view_routes 
order by A


--������ 9
--��������� ���������� ����� �����������, ���������� ������� �������, �������� � ���������� ������������ 
--���������� ���������  � ���������, ������������� ��� ����� *
--* - � �������� ���� ���������� ��������� � ������� airports_data.coordinates - ���������, ��� � ��������. 
--� ��������� ���� ���������� ��������� � �������� airports.longitude � airports.latitude.

--����: ������ ���, � ������� ��������� ��� �������� � �������� � �� ������������, � ����� � ��������� � �� ���������� �����, �����
-- � �������, ��������� ��� �� ������� ���������� ������ ����� ����� ��������, � �����
--���������� ��������� ������� � ����� �������� � ������� ���� �������������� �� ��� WARNING - ���������


with cte1 as(
			select fv.flight_id, fv.departure_airport, a3.latitude as d1, a3.longitude as d2, fv.arrival_airport, a1.latitude as a1,
					a1.longitude as a2, fv.aircraft_code, a2."range"
			from flights_v fv 
			join aircrafts a2 on a2.aircraft_code = fv.aircraft_code 
			join airports a1 on a1.city = fv.arrival_city 
			join airports a3 on a3.city = fv.departure_city 
			)
select flight_id, departure_airport, d1, d2, arrival_airport, a1, a2, aircraft_code, "range", 
	(acos(sind(d1) * sind (a1) + cosd(d1) * cosd(a1) * cosd(d2-a2)) * 6371) as L_theory,
	case
		 when (acos(sind(d1) * sind (a1) + cosd(d1) * cosd(a1) * cosd(d2-a2)) * 6371) > "range" then 'WARNING'
		 when (acos(sind(d1) * sind (a1) + cosd(d1) * cosd(a1) * cosd(d2-a2)) * 6371) <= "range" then 'Ok'
	end as info
from cte1