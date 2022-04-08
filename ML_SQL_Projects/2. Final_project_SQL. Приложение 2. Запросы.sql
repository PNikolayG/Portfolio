-- Проектная работа по модулю "SQL и получение данных". Приложение 2. Запросы

--Задача 1
-- В каких городах больше одного аэропорта?

-- Идея: взять города и посчитать их аэропорты при помощи агрегатной функции count()
-- при этом сгруппировать и отобрать те, у которых количество более 1 при помощи having
-- также дополнительно идёт сортировка по алфавиту 


select city, count(airport_name) as total_number_airports
from airports a 
group by city 
having count(airport_name) > 1
order by city;

--Задача 2
-- В каких аэропортах есть рейсы, выполняемые самолётом с максимальной дальностью перелёта? 

--Идея: ответ на конкретный вопрос (без указания длаьности и марки этого самолёта)
--был сделан подзапрос выбирайщий максимальное значение дальности самолёта на случай изменения данных
-- этот подзапрос был использован для выбора марки-кода самолёта с этой дальностью
--далее уже был выбран код аэропорта, где этот самолёт отправляется/приземляется
--а чтобы стало понятнее, расшифрован этот код, путём связки с названием аэропорта и сортирован по кодам аэропортов

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

--Задача 3
--Вывести 10 рейсов с максимальным временем задержки вылета

--Идея: для наглядности и идентификации рейса были выбраны следующие параметры для отображения: номер рейса, 
-- время отправления по расписанию и актуальное, задержка как разность предыдущих параметров,
-- аэропорт отправления и прибытия
-- далее отсечка тех рейсов, где нет данных (NULL) по временам, сортировка по убыванию задержки
--выборка первых 10 при помощи limit

select flight_no, scheduled_departure, actual_departure, (actual_departure - scheduled_departure) as delay, departure_airport, arrival_airport 
from flights f2 
where (actual_departure - scheduled_departure) is not NULL
order by delay desc 
limit 10;

--Задача 4
--Были ли брони, по которым не были получены посадочные талоны?
 
--Идея: для начала присоединить к таблице с большим значением, т.е. с бронью, таблицу с посадочными
-- талонами, тогда сразу увидим, где нестыковки, так как там будут Null
--далее выберем строки, где NULL и посчитаем количество с выводом на экран это и будет ответ 

select count(*) as without_board_pass
from tickets t3 
left join boarding_passes bp on t3.ticket_no = bp.ticket_no 
where bp.boarding_no is null;

--Задача 5
--Найдите свободные места для каждого рейса, их % отношение к общему количеству мест в самолете.
--Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров 
--из каждого аэропорта на каждый день. Т.е. в этом столбце должна отражаться накопительная сумма - сколько 
--человек уже вылетело из данного аэропорта на этом или более ранних рейсах за день.


--Идея: расчёт мест за счёт подзапросов: первый - расчёт занятых мест по пасодочным талоном отсортированных по перелётам
-- второй - расчёт общего числа мест для каждой модели самолёта по подсчёту мест
--далее объединение результатов при помощи join- ов и использование оконной функции в select для обозначения накопления по аэропорту и по дням

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

--Задача 6
--Найдите процентное соотношение перелетов по типам самолетов от общего количества.

--Идея: при помощи СТЕ (ОТВ) посчитать количество перелётов по каждой модели самолёта, а также 
--в дальнейшем для расчёта и использования суммы всех перелётов, далее ведётся расчёт отношения
-- количества перелётов к общему числу перелётов и округляется до второго знака
--для удобства и наглядности сортировка по алфавиту

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


--Задача 7
--Были ли города, в которые можно добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета?

--Идея: в СТЕ (ОТВ) происходит расчёт минимального значения по flight_id - перелётам, а дальше уже в запросе при помощи СТЕ происходит отбор тех строк в таблице, которые равны этому минимуму и при этом
--являются Business классом, вывод по перелёту, аэропорту, городу, так как это считаю важной информацией для заказчика 
--на каком перелёте, что за имя аэропорта и город

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
	

--Задача 8
--Между какими городами нет прямых рейсов?

--Идея: в материализованном представлении маршруты рейсов расшифрованы из абривиатур аэропортов 
--в название городов и благодаря двойному join составлены все маршруты какие есть
-- в запрос путём декартового произведения были полученые все возможные машруты, которые могли бы быть
--исключены маршруты типа из А в А (where), а также исключены (except) те маршруты, которые есть
--отсортированы для удобства, отслеживания и провеки

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


--Задача 9
--Вычислите расстояние между аэропортами, связанными прямыми рейсами, сравните с допустимой максимальной 
--дальностью перелетов  в самолетах, обслуживающих эти рейсы *
--* - В облачной базе координаты находятся в столбце airports_data.coordinates - работаете, как с массивом. 
--В локальной базе координаты находятся в столбцах airports.longitude и airports.latitude.

--Идея: создаём СТЕ, в котором соединяем все маршруты с городами и их координатами, а также с самолётами и их дальностью полёта, далее
-- в запросе, используя СТЕ по формуле производим расчёт длины этого маршрута, а также
--сравниваем дальность самолёта и длину маршрута и выводим ИНФО предупреждения Ок или WARNING - опасность


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