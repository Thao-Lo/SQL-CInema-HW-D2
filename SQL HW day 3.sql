# 1. Show film which dont have any screening
SELECT *
FROM film f
WHERE f.id NOT IN 
	(SELECT screening.film_id FROM screening);
    
# 2. Who book more than 1 seat in 1 booking
SELECT 
c.first_name, c.last_name, COUNT(r.booking_id) AS NoOfBookedSeat
FROM customer c
JOIN booking b 
	ON c.id = b.customer_id
JOIN reserved_seat r
	ON r.booking_id = b.id
GROUP BY r.booking_id
HAVING NoOfBookedSeat > 1;

#3. Show room show more than 2 film in one day
SELECT
DATE(start_time) AS s_date,
	room_id,  COUNT(distinct film_id) AS NoOfFilm,
   r.name
FROM screening s 
JOIN room r ON r.id = s.room_id
GROUP BY s.room_id, s_date 
HAVING NoOfFilm > 1 
ORDER BY s_date asc, room_id asc;

# 4. which room show the least film?
SELECT room_id, COUNT(distinct film_id) AS NoOfFilm	
FROM screening s
GROUP BY room_id
HAVING NoOfFilm = 
(SELECT NoOfFilm 
FROM 
	(SELECT 
	room_id, COUNT(distinct film_id) AS NoOfFilm	
FROM screening
GROUP BY room_id
ORDER BY NoOfFilm ASC
LIMIT 1) rooms);

# 5. what film don't have booking
SELECT film.name 
FROM film 
WHERE film.name NOT IN (SELECT 
	f.name
FROM film f
JOIN screening s ON f.id = s.film_id
JOIN booking b ON b.screening_id = s.id
GROUP BY film_id);

# 6. WHAT film have show the biggest number of room?
SELECT 
	s.film_id, COUNT(distinct s.room_id) AS NoOfRoom,
    f.name
FROM screening s
JOIN film f ON s.film_id = f.id
GROUP BY s.film_id 
HAVING NoOfRoom = (
SELECT 
COUNT(distinct se.room_id) AS NoOfRoom
FROM screening se
GROUP BY se.film_id
ORDER BY COUNT(distinct se.room_id) desc
LIMIT 1);

# 7. Show number of film that show in every day of week and order descending
SELECT DAYNAME(s.start_time) AS DayOfWeek,
 COUNT(distinct film_id) AS NoOfFilm
FROM screening s
GROUP BY DayOfWeek
ORDER BY DayOfWeek desc; 

SELECT DAYOFWEEK(s.start_time) AS DayOfWeek,
 COUNT(distinct film_id) AS NoOfFilm
FROM screening s
GROUP BY DayOfWeek
ORDER BY NoOfFilm desc; 

# 8. show total length of each film that showed in 28/5/2022
SELECT DATE(s.start_time) AS selectedDay, 
COUNT(s.film_id), s.film_id, SUM(f.length_min)
FROM screening s
JOIN film f ON f.id = s.film_id
WHERE DATE(s.start_time) = '2022-05-28'
GROUP BY s.film_id, DATE(s.start_time)
ORDER BY s.film_id asc;

# 9. What film has showing time above and below average show time of all film
#----------------Answer-----------------
SELECT COUNT(s.film_id) AS totalFilm, 
f.name,
f.length_min * COUNT(s.film_id) AS totalShowTime
FROM screening s
JOIN film f ON s.film_id = f.id
GROUP BY film_Id
HAVING totalShowTime < (
SELECT AVG(totalShowTime) AS avgShowTime
FROM(
SELECT 
f.length_min * COUNT(s.film_id) AS totalShowTime
FROM screening s
JOIN film f ON s.film_id = f.id
GROUP BY s.film_id) AS avgShowTime); 

# 10. what room have least number of seat?
SELECT se.room_id, 
COUNT(se.id) AS NoOfSeat, 
r.name
FROM seat se
JOIN room r ON r.id = se.room_id
GROUP BY se.room_id
ORDER BY NoOfSeat ASC
LIMIT 1;

#11. what room have number of seat bigger than average number of seat of all rooms
SELECT 
	COUNT(se.id) AS NoOfSeat, 
	r.name
FROM seat se
JOIN room r ON se.room_id = r.id
GROUP BY se.room_id
HAVING NoOfSeat > (
SELECT AVG(NoOfSeat) 
FROM (
SELECT 
COUNT(se.id) AS NoOfSeat
FROM seat se
GROUP BY se.room_id) AS Average);

#12 Ngoai nhung seat mà Ong Dung booking duoc o booking id = 1 thi ong CÓ THỂ (CAN) booking duoc nhung seat nao khac khong?
#----------------Answer-----------------
SELECT availableSeat.id 
FROM (
SELECT se.id, se.room_id
FROM seat se
WHERE se.room_id = 
(SELECT room.id AS room_ID
FROM screening s
JOIN room ON room.id = s.room_id
WHERE s.id = 
( SELECT b.screening_id
FROM booking b
JOIN customer c ON b.customer_id = c.id
WHERE b.id = '1'
LIMIT 1))) AS availableSeat
WHERE availableSeat.id  NOT IN (
SELECT se.id 
FROM seat se
JOIN reserved_seat r ON se.id = r.seat_id
JOIN booking b ON b.id = r.booking_id 
JOIN screening s ON s.id = b.screening_id
JOIN room ON room.id = s.room_id
WHERE screening_ID = 
( SELECT b.screening_id
FROM booking b
JOIN customer c ON b.customer_id = c.id
WHERE b.id = '1'
LIMIT 1)) ;

# 13.Show Film with total screening and order by total screening. BUT ONLY SHOW DATA OF FILM WITH TOTAL SCREENING > 10
SELECT 
	COUNT(s.film_id) AS totalScreening, 
	f.id, f.name, f.country_code, f.length_min, f.type
FROM screening s
JOIN film f ON f.id = s.film_id
GROUP BY s.film_id
HAVING totalScreening > 10
ORDER BY totalScreening desc;

# 14.TOP 3 DAY OF WEEK based on total booking
#----------------Answer-----------------
SELECT 
	COUNT(b.screening_id) AS totalBooking,
    dayofweek(s.start_time) AS dayOfWeek
FROM booking b
RIGHT JOIN screening s ON b.screening_id = s.id 
GROUP BY dayofweek(s.start_time)
ORDER BY totalBooking DESC
LIMIT 3; 

# 15.CALCULATE BOOKING rate over screening of each film ORDER BY RATES.
SELECT totalBookingTable.totalBooking, totalScreenTable.totalScreening,
totalBookingTable.name,
CONCAT(ROUND(((totalBookingTable.totalBooking/totalScreenTable.totalScreening) * 100), 2),'%') AS percentage
FROM (
SELECT f.name, f.id, COUNT(b.screening_id) AS totalBooking
FROM film f
LEFT JOIN screening s ON s.film_id = f.id
LEFT JOIN booking b ON b.screening_id = s.id 
GROUP BY f.id) AS totalBookingTable
JOIN (SELECT COUNT(s.film_id) AS totalScreening, f.id
FROM screening s
RIGHT JOIN film f ON s.film_id = f.id
GROUP BY f.id
ORDER BY f.id asc) AS totalScreenTable ON totalBookingTable.id = totalScreenTable.id  
ORDER BY percentage desc;

# 16.CONTINUE Q15 -> WHICH film has rate over average ?.
SELECT totalBookingTable.totalBooking, totalScreenTable.totalScreening,
totalBookingTable.name,
CONCAT(ROUND(((totalBookingTable.totalBooking/totalScreenTable.totalScreening) * 100), 2),'%') AS percentage
FROM (
SELECT f.name, f.id, COUNT(b.screening_id) AS totalBooking
FROM film f
LEFT JOIN screening s ON s.film_id = f.id
LEFT JOIN booking b ON b.screening_id = s.id 
GROUP BY f.id) AS totalBookingTable
JOIN (SELECT COUNT(s.film_id) AS totalScreening, f.id
FROM screening s
RIGHT JOIN film f ON s.film_id = f.id
GROUP BY f.id
ORDER BY f.id asc) AS totalScreenTable ON totalBookingTable.id = totalScreenTable.id  
WHERE CONCAT(ROUND(((totalBookingTable.totalBooking/totalScreenTable.totalScreening) * 100), 2),'%') > 
	(
	SELECT ROUND(AVG(rateTable.percentage),2) AS averageRate
	FROM (SELECT 
	totalBookingTable.totalBooking, totalScreenTable.totalScreening,
	totalBookingTable.name,
	CONCAT(ROUND(((totalBookingTable.totalBooking/totalScreenTable.totalScreening) * 100), 2),'%') AS percentage
	FROM (
	SELECT f.name, f.id, COUNT(b.screening_id) AS totalBooking
	FROM film f
	LEFT JOIN screening s ON s.film_id = f.id
	LEFT JOIN booking b ON b.screening_id = s.id 
	GROUP BY f.id) AS totalBookingTable
	JOIN (SELECT COUNT(s.film_id) AS totalScreening, f.id
	FROM screening s
	RIGHT JOIN film f ON s.film_id = f.id
	GROUP BY f.id
	ORDER BY f.id asc) AS totalScreenTable ON totalBookingTable.id = totalScreenTable.id  
	ORDER BY percentage desc) AS rateTable);

# 17.TOP 2 people who enjoy the least TIME (in minutes) in the cinema based on booking info - only count who has booking info
SELECT c.first_name, f.name, SUM(f.length_min) AS enjoyTime
FROM customer c
JOIN booking b ON b.customer_id = c.id
JOIN reserved_seat r ON b.id = r.booking_id
JOIN screening s ON s.id = b.screening_id
JOIN film f ON f.id = s.film_id
GROUP BY c.id, f.name
ORDER BY enjoyTime ASC
LIMIT 2;









