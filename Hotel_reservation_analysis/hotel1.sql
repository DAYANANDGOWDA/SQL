create database hotel;

use hotel;
show tables;
rename table  hotel_reservation_dataset to hotel;

desc hotel;
UPDATE hotel SET arrival_date = STR_TO_DATE(arrival_date, '%d-%m-%Y');
alter table hotel modify arrival_date date;

# 1. Retrieve all records from the hotel reservation table.
select * from hotel;

# 2. Show the top 5 most expensive room bookings by avg_price_per_room
select room_type_reserved, avg_price_per_room from hotel order by avg_price_per_room desc limit 5;

# 3. Count the number of reservations with more than two children.
select count(*) More_then_two_childrens from hotel where no_of_children >2;

# 4. List all unique meal plans offered.
select distinct type_of_meal_plan from hotel;

# 5. Count reservations by room type
select room_type_reserved, count(room_type_reserved) as No_of_Reservation 
from hotel group by room_type_reserved;

# 6. Find the total revenue (sum of avg_price_per_room ) for all bookings.
select sum(avg_price_per_room * (no_of_week_nights + no_of_weekend_nights))  Total_Revenue from hotel;

# 7. Show the number of bookings for each month.
select monthname(arrival_date)  Month_Name, count(*) Total_Bookings from hotel 
group by month(arrival_date),monthname(arrival_date) ;

# 8. What is the average stay duration (no_of_weekend_nights + no_of_week_nights)?
select avg(no_of_weekend_nights + no_of_week_nights) Avg_Stay_Duration from hotel;

# 9. Find the most common market segment type.
select market_segment_type , count(*) cnt from hotel group by market_segment_type order by cnt desc limit 1;

#  10. Retrieve all bookings made on a Monday.
select * from hotel where dayname(arrival_date) = 'Monday';

# 11. How many guests stayed with children vs. without children?
select case 
	when no_of_children > 0 then "With_Childrens"
    else 'Without_Childrens'
    end children_cat,
    count(*) Total_Bookings 
from hotel group by children_cat;

#12. Show booking IDs with a stay longer than 7 days.
select Booking_ID, (no_of_weekend_nights +no_of_week_nights) No_Of_Days from hotel 
where (no_of_weekend_nights +no_of_week_nights)>7;

#13. What is the cancellation rate?
select count(case when booking_status = 'Not_Canceled' then 1 end)*100/count(*) Cancellation_Rate from hotel ;

#14. List bookings where the avg_price_per_room is above the monthly average.
With monthly_avg as (select month(arrival_date) Month, avg(avg_price_per_room) avg_monthly_price from hotel
group by month(arrival_date))
select h.* from hotel h join monthly_avg m  ON MONTH(h.arrival_date) = m.month where avg_price_per_room > avg_monthly_price;

#15. List the top 3 meal plans by total revenue.
select type_of_meal_plan, sum(avg_price_per_room * (no_of_week_nights + no_of_weekend_nights))  Total_Revenue 
from hotel group by type_of_meal_plan order by Total_Revenue desc limit 3;

#16. Show the average room price by market segment.
select market_segment_type, avg(avg_price_per_room) Avg_price from hotel group by market_segment_type;

#17. Find duplicate booking IDs (if any).
select Booking_ID, count(*) cnt from hotel group by Booking_ID having count(*) >1;

#18. Show reservations with the same arrival date.
select  * from hotel where arrival_date in 
(select arrival_date from hotel group by arrival_date having count(*)>1)
order by arrival_date;

#19. Find the earliest and latest booking dates
select min(arrival_date) as Earliest_Booking , max(arrival_date) Latest_ooking from hotel;

#20. Show the daily number of bookings in January.
select arrival_date as Date , count(*) NO_of_Bookings from hotel where month(arrival_date) = 1 
group by arrival_date order by arrival_date;

#21. Find customers who booked both weekday and weekend nights.
select * from hotel where no_of_weekend_nights >= 1 and no_of_week_nights >= 1;

#22. Group bookings by length of stay (1–3 days, 4–7 days, 8+ days).
select (
	case 
		when (no_of_weekend_nights + no_of_week_nights) between 1 and 3 then '1-3 days'
        when (no_of_weekend_nights + no_of_week_nights) between 4 and 7 then '4-7 days'
        when (no_of_weekend_nights + no_of_week_nights) >=8 then '8+ days'
        else '0 days'
        End
        ) Stay_len_cat,
count(*) No_of_Bookings
from hotel group by Stay_len_cat
order by No_of_Bookings;
        
#23. Identify peak booking months and compare year-on-year growth.
WITH monthly_bookings AS (
    SELECT
        YEAR(arrival_date) AS year,
        MONTH(arrival_date) AS month,
        COUNT(*) AS total_bookings
    FROM 
        hotel
    GROUP BY 
        YEAR(arrival_date), MONTH(arrival_date)
),
growth_calc AS (
    SELECT
        year,
        month,
        total_bookings,
        LAG(total_bookings) OVER (PARTITION BY month ORDER BY year) AS previous_year_bookings
    FROM 
        monthly_bookings
)

SELECT 
    year,
    month,
    total_bookings,
    previous_year_bookings,
    ROUND(
        (total_bookings - previous_year_bookings) * 100.0 / previous_year_bookings,
        2
    ) AS yoy_growth_percent
FROM 
    growth_calc
WHERE 
    previous_year_bookings IS NOT NULL
ORDER BY 
    month, year;
    
#24. Compare average stay durations between different meal plans.
select type_of_meal_plan, avg(no_of_weekend_nights+no_of_week_nights) as Avg_Stay_duration from hotel
group by type_of_meal_plan;

#25. Use a CTE to calculate average revenue per month, then list months above the overall average.
WITH monthly_revenue AS (
    SELECT 
        MONTH(arrival_date) AS month,
        YEAR(arrival_date) AS year,
        SUM(avg_price_per_room) AS total_revenue
    FROM 
        hotel
    GROUP BY 
        YEAR(arrival_date), MONTH(arrival_date)
),
overall_avg AS (
    SELECT 
        AVG(total_revenue) AS avg_monthly_revenue
    FROM 
        monthly_revenue
)

SELECT 
    mr.month,
    mr.year,
    mr.total_revenue
FROM 
    monthly_revenue mr
JOIN 
    overall_avg oa ON mr.total_revenue > oa.avg_monthly_revenue
ORDER BY 
    mr.total_revenue DESC;

#26. Use a window function to calculate running total of bookings by date.
SELECT 
    arrival_date,
    COUNT(*) AS daily_bookings,
    SUM(COUNT(*)) OVER (ORDER BY arrival_date) AS running_total_bookings
FROM 
    hotel
GROUP BY 
    arrival_date
ORDER BY 
    arrival_date;

#27. Create a moving average of price over 7 days.
WITH daily_avg AS (
    SELECT 
        arrival_date,
        AVG(avg_price_per_room) AS avg_price_per_day
    FROM 
        hotel
    GROUP BY 
        arrival_date
)

SELECT 
    arrival_date,
    avg_price_per_day,
    ROUND(
        AVG(avg_price_per_day) OVER (
            ORDER BY arrival_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ), 2
    ) AS moving_avg_7_day
FROM 
    daily_avg
ORDER BY 
    arrival_date;
    
#28. Identify price outliers using standard deviation and Z-Score.
WITH stats AS (
    SELECT 
        AVG(avg_price_per_room) AS mean_price,
        STDDEV(avg_price_per_room) AS std_dev
    FROM 
        hotel
),
z_scored AS (
    SELECT 
        *,
        (avg_price_per_room - s.mean_price) / s.std_dev AS z_score
    FROM 
        hotel h
    CROSS JOIN stats s
)
SELECT *
FROM z_scored
WHERE ABS(z_score) > 3
ORDER BY z_score DESC;

#29. Calculate year-over-year growth in bookings using CTEs.
WITH yearly_bookings AS (
    SELECT 
        YEAR(arrival_date) AS year,
        COUNT(*) AS total_bookings
    FROM 
        hotel
    GROUP BY 
        YEAR(arrival_date)
),
yoy_growth AS (
    SELECT 
        year,
        total_bookings,
        LAG(total_bookings) OVER (ORDER BY year) AS previous_year_bookings
    FROM 
        yearly_bookings
)
SELECT 
    year,
    total_bookings,
    previous_year_bookings,
    ROUND(
        ((total_bookings - previous_year_bookings) * 100.0) / previous_year_bookings, 2
    ) AS yoy_growth_percent
FROM 
    yoy_growth
WHERE 
    previous_year_bookings IS NOT NULL
ORDER BY 
    year;
    
#30. Find 3-day periods with maximum bookings using a sliding window.
WITH daily_bookings AS (
    SELECT 
        arrival_date,
        COUNT(*) AS bookings
    FROM 
        hotel
    GROUP BY 
        arrival_date
),
rolling_sum AS (
    SELECT 
        arrival_date,
        bookings,
        SUM(bookings) OVER (
            ORDER BY arrival_date
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS rolling_3_day_bookings
    FROM 
        daily_bookings
)
SELECT *
FROM rolling_sum
ORDER BY rolling_3_day_bookings DESC
LIMIT 5;

#31. Use a LEAD() function to find gaps between bookings per guest.
SELECT 
    Booking_ID,
    arrival_date,
    LEAD(arrival_date) OVER (ORDER BY arrival_date) AS next_arrival_date,
    DATEDIFF(
        LEAD(arrival_date) OVER (ORDER BY arrival_date), 
        arrival_date
    ) AS gap_days
FROM 
    hotel
ORDER BY 
    arrival_date;
    
#32. Create a CTE that flags long stays (>10 nights) and summarizes them by month.
WITH long_stays AS (
    SELECT 
        arrival_date,
        no_of_weekend_nights + no_of_week_nights AS total_nights
    FROM 
        hotel
    WHERE 
        (no_of_weekend_nights + no_of_week_nights) > 10
)
SELECT 
    YEAR(arrival_date) AS year,
    MONTH(arrival_date) AS month,
    COUNT(*) AS long_stay_bookings
FROM 
    long_stays
GROUP BY 
    YEAR(arrival_date), MONTH(arrival_date)
ORDER BY 
    year, month;
    
#33. Self-join the table to compare bookings made on the same date for different room types.
SELECT 
    a.arrival_date,
    a.room_type_reserved AS room_type_a,
    b.room_type_reserved AS room_type_b,
    a.avg_price_per_room AS price_a,
    b.avg_price_per_room AS price_b
FROM 
    hotel a
JOIN 
    hotel b 
    ON a.arrival_date = b.arrival_date
    AND a.room_type_reserved <> b.room_type_reserved
    AND a.Booking_ID < b.Booking_ID  -- Avoid duplicate pairs and self-pairs
ORDER BY 
    a.arrival_date
LIMIT 100;

#34. Use CASE statements to categorize bookings as low, medium, or high cost.
SELECT 
    Booking_ID,
    arrival_date,
    avg_price_per_room,
    CASE 
        WHEN avg_price_per_room < 100 THEN 'Low'
        WHEN avg_price_per_room BETWEEN 100 AND 200 THEN 'Medium'
        ELSE 'High'
    END AS cost_category
FROM 
    hotel
ORDER BY 
    avg_price_per_room;

#35. Create a cohort analysis of first-time bookings by month using CTEs.
WITH first_booking AS (
    SELECT
        room_type_reserved,
        no_of_adults,
        no_of_children,
        MIN(arrival_date) AS first_booking_date
    FROM 
        hotel
    GROUP BY 
        room_type_reserved, no_of_adults, no_of_children
),
cohort_grouping AS (
    SELECT
        DATE_FORMAT(first_booking_date, '%Y-%m') AS cohort_month,
        COUNT(*) AS num_first_time_guests
    FROM 
        first_booking
    GROUP BY 
        cohort_month
)

SELECT 
    cohort_month,
    num_first_time_guests
FROM 
    cohort_grouping
ORDER BY 
    cohort_month;

#36. Identify guests with price sensitivity using variance in their room prices.
SELECT
    room_type_reserved,
    no_of_adults,
    no_of_children,
    COUNT(*) AS booking_count,
    ROUND(AVG(avg_price_per_room), 2) AS avg_price,
    ROUND(STDDEV(avg_price_per_room), 2) AS price_std_dev
FROM
    hotel
GROUP BY
    room_type_reserved,
    no_of_adults,
    no_of_children
HAVING 
    booking_count > 1
ORDER BY 
    price_std_dev DESC
LIMIT 20;

#37. Analyze the effect of children on room price using window averages.
SELECT 
    Booking_ID,
    room_type_reserved,
    no_of_children,
    avg_price_per_room,
    AVG(avg_price_per_room) OVER (
        PARTITION BY room_type_reserved, 
                     CASE WHEN no_of_children > 0 THEN 'With Children' ELSE 'Without Children' END
    ) AS avg_price_by_children_group,
    CASE 
        WHEN no_of_children > 0 THEN 'With Children'
        ELSE 'Without Children'
    END AS children_flag
FROM 
    hotel
ORDER BY 
    room_type_reserved, children_flag;

#38.Create a bookings funnel using counts of leads → bookings → cancellations.
SELECT 'Leads' AS stage, COUNT(*) AS count
FROM hotel

UNION ALL

SELECT 'Bookings' AS stage, COUNT(*) AS count
FROM hotel
WHERE booking_status = 'Not_Canceled'

UNION ALL

SELECT 'Cancellations' AS stage, COUNT(*) AS count
FROM hotel
WHERE booking_status = 'Canceled';

SELECT 
    COUNT(*) AS total_reservations,
    SUM(CASE WHEN booking_status = 'Not_Canceled' THEN 1 ELSE 0 END) AS confirmed_bookings,
    SUM(CASE WHEN booking_status = 'Canceled' THEN 1 ELSE 0 END) AS cancellations
FROM hotel;

#39. What is the average price per room for reservations involving children? 
SELECT AVG(avg_price_per_room) AS average_price_with_children
FROM hotel
WHERE no_of_children > 0;

#40. How many reservations were made for the year 20XX (replace XX with the desired year)? 
SELECT COUNT(*) AS total_reservations
FROM hotel
WHERE YEAR(STR_TO_DATE(arrival_date, '%Y-%m-%d')) = 2017;

#41. What is the highest and lowest lead time for reservations?  
SELECT 
    MAX(lead_time) AS highest_lead_time,
    MIN(lead_time) AS lowest_lead_time
FROM hotel;

#42. What is the most common market segment type for reservations?  
SELECT market_segment_type, COUNT(*) AS segment_count
FROM hotel
GROUP BY market_segment_type
ORDER BY segment_count DESC
LIMIT 1;

#43. How many reservations have a booking status of "Confirmed"? 
SELECT COUNT(*) AS confirmed_reservations
FROM hotel
WHERE booking_status = 'Not_Canceled';

#44. What is the total number of adults and children across all reservations?  
SELECT 
    SUM(no_of_adults) AS total_adults,
    SUM(no_of_children) AS total_children
FROM hotel;

#45.  What is the average number of weekend nights for reservations involving children?  
SELECT AVG(no_of_weekend_nights) AS avg_weekend_nights_with_children
FROM hotel
WHERE no_of_children > 0;

#46.  How many reservations were made in each month of the year? 
SELECT year(arrival_date) Year, MONTH(STR_TO_DATE(arrival_date, '%Y-%m-%d')) AS reservation_month,
       COUNT(*) AS total_reservations
FROM hotel
GROUP BY reservation_month, Year
ORDER BY Year,reservation_month;

#47. What is the average number of nights (both weekend and weekday) spent by guests for each room type? 
SELECT room_type_reserved,
       AVG(no_of_weekend_nights + no_of_week_nights) AS avg_nights_per_room_type
FROM hotel
GROUP BY room_type_reserved
ORDER BY room_type_reserved;

#48.  For reservations involving children, what is the most common room type, and what is the average price for that room type?  
SELECT room_type_reserved,
       AVG(avg_price_per_room) AS avg_price_per_room_type,
       COUNT(*) AS reservation_count
FROM hotel
WHERE no_of_children > 0
GROUP BY room_type_reserved
ORDER BY reservation_count DESC
LIMIT 1;

#49. Find the market segment type that generates the highest average price per room. 
SELECT market_segment_type,
       AVG(avg_price_per_room) AS avg_price_per_room
FROM hotel
GROUP BY market_segment_type
ORDER BY avg_price_per_room DESC
LIMIT 1;

#50. How many reservations fall on a weekend (no_of_weekend_nights > 0)?  
SELECT COUNT(*) AS weekend_reservations
FROM hotel
WHERE no_of_weekend_nights > 0;


select * from hotel;