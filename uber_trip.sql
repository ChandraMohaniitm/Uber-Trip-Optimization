-- Q3. TRIP DURATION
SELECT 
    "Trip ID",
    "Pickup Time",
    "Drop Off Time",
    ROUND(EXTRACT(EPOCH FROM ("Drop Off Time" - "Pickup Time")) / 60, 2) AS trip_duration_min
FROM 
    public.trip
ORDER BY 
    4 DESC;

-- Q4. TRIPS WITH LONG DURATION BUT SHORT DISTANCE(Probably High Traffic Area)
SELECT 
    "Trip ID",
    ROUND(EXTRACT(EPOCH FROM ("Drop Off Time" - "Pickup Time")) / 60, 2) AS trip_duration_min,
    "trip_distance",
    CASE 
        WHEN EXTRACT(EPOCH FROM ("Drop Off Time" - "Pickup Time")) / 60 > 60 AND trip_distance < 3 THEN '⚠ Suspicious'
        ELSE 'Normal'
    END AS status
FROM 
    public.trip
WHERE 
    ("Drop Off Time" - "Pickup Time") IS NOT NULL
ORDER BY 
    "trip_distance" desc

-- Q5. THIS REVEALS LOCATION-BASED OR TIME-SPECIFIC DELAYS
SELECT 
    pl."Location" AS pickup_location,
    CASE 
        WHEN EXTRACT(HOUR FROM t."Pickup Time") BETWEEN 5 AND 11 THEN 'Morning'
        WHEN EXTRACT(HOUR FROM t."Pickup Time") BETWEEN 12 AND 16 THEN 'Afternoon'
        WHEN EXTRACT(HOUR FROM t."Pickup Time") BETWEEN 17 AND 21 THEN 'Evening'
        ELSE 'Night'
    END AS time_of_day,
    ROUND(AVG(EXTRACT(EPOCH FROM ("Drop Off Time" - "Pickup Time")) / 60), 2) AS avg_trip_duration_min,
    COUNT(*) AS trip_count
FROM 
    public.trip t
JOIN 
    public.location pl ON t."PULocationID" = pl."LocationID"
GROUP BY 
    pl."Location", time_of_day
ORDER BY 
    3 desc

-- Q6. HIGH SURGE COST BY PICKUP LOCATION AND TIME
SELECT 
    t."Trip ID",
    pl."Location" AS pickup_location,
    pl."City" AS pickup_city,
    t."Pickup Time",
    t."Surge Fee"
FROM 
    public.trip t
JOIN 
    public.location pl ON t."PULocationID" = pl."LocationID"
WHERE 
    t."Surge Fee" IS NOT NULL
ORDER BY 
    t."Surge Fee" desc
LIMIT 20;


--Q7. PEAK HOURS FOR SURGE PRICING
SELECT 
    CASE 
        WHEN EXTRACT(HOUR FROM t."Pickup Time") BETWEEN 5 AND 11 THEN 'Morning'
        WHEN EXTRACT(HOUR FROM t."Pickup Time") BETWEEN 12 AND 16 THEN 'Afternoon'
        WHEN EXTRACT(HOUR FROM t."Pickup Time") BETWEEN 17 AND 21 THEN 'Evening'
        ELSE 'Night'
    END AS time_of_day,
    ROUND(AVG(t."Surge Fee"), 2) AS avg_surge_fee,
    COUNT(*) AS trip_count
FROM 
    public.trip t
WHERE 
    t."Surge Fee" IS NOT NULL
GROUP BY 
    "time_of_day"
ORDER BY 
    2 desc

--Q8. PICKUP AREAs WITH HIGH AVG SURGE FEE
SELECT 
    pl."Location" AS pickup_location,
    pl."City",
    ROUND(AVG(t."Surge Fee"), 2) AS avg_surge_fee,
    COUNT(*) AS trip_count
FROM 
    public.trip t
JOIN 
    public.location pl ON t."PULocationID" = pl."LocationID"
WHERE 
    t."Surge Fee" IS NOT NULL
GROUP BY 
    pl."Location", pl."City"
HAVING 
    COUNT(*) > 10
ORDER BY 
    3 DESC
LIMIT 20;

--Q9. CUMULATIVE VEHICLE TYPE PERFORMANCE 
SELECT 
    t."Vehicle",
    COUNT(*) AS total_trips,
    ROUND(SUM(t.fare_amount)::numeric, 2) AS total_fare_amount,
    ROUND(SUM(t.trip_distance)::numeric, 2) AS total_trip_distance,
    ROUND(SUM(EXTRACT(EPOCH FROM ("Drop Off Time" - "Pickup Time")) / 60)::numeric, 2) AS total_trip_duration_min,
    ROUND(AVG(t.fare_amount)::numeric, 2) AS avg_fare_per_trip,
    ROUND(AVG(t.trip_distance)::numeric, 2) AS avg_distance_per_trip,
    ROUND(AVG(EXTRACT(EPOCH FROM ("Drop Off Time" - "Pickup Time")) / 60)::numeric, 2) AS avg_duration_per_trip_min
FROM 
    public.trip t
WHERE 
    t."Drop Off Time" IS NOT NULL AND t."Pickup Time" IS NOT NULL
GROUP BY 
    t."Vehicle"
ORDER BY 
    total_fare_amount DESC;

--Q10. COUNT OF TRIPS BY LOCATION
SELECT 
    l."LocationID",
    l."Location",
    l."City",
    COUNT(t."Trip ID") AS pickup_trip_count
FROM 
    public.location l
LEFT JOIN 
    public.trip t ON l."LocationID" = t."PULocationID"
GROUP BY 
    l."LocationID", l."Location", l."City"
ORDER BY 
    pickup_trip_count ASC;

--Q11. COUNT OF TRIPS BY DROP LOCATIONS
SELECT 
    l."LocationID",
    l."Location",
    l."City",
    COUNT(t."Trip ID") AS drop_trip_count
FROM 
    public.location l
LEFT JOIN 
    public.trip t ON l."LocationID" = t."DOLocationID"
GROUP BY 
    l."LocationID", l."Location", l."City"
ORDER BY 
    drop_trip_count ASC;


--Q12. LOCATIONS WITH ZERO OR VERY LOW TOTAL USAGE
SELECT 
    l."LocationID",
    l."Location",
    l."City",
    COALESCE(p.pickup_count, 0) AS pickup_trips,
    COALESCE(d.drop_count, 0) AS drop_trips,
    COALESCE(p.pickup_count, 0) + COALESCE(d.drop_count, 0) AS total_activity
FROM 
    public.location l
LEFT JOIN (
    SELECT "PULocationID", COUNT(*) AS pickup_count
    FROM public.trip
    GROUP BY "PULocationID"
) p ON l."LocationID" = p."PULocationID"
LEFT JOIN (
    SELECT "DOLocationID", COUNT(*) AS drop_count
    FROM public.trip
    GROUP BY "DOLocationID"
) d ON l."LocationID" = d."DOLocationID"
ORDER BY 
    total_activity ASC;
	
--Q13. PASSENGERS BEHAVIOR
SELECT 
    passenger_count,
    COUNT(*) AS trip_count,
    ROUND(AVG(trip_distance)::numeric, 2) AS avg_distance,
    ROUND(AVG(fare_amount)::numeric, 2) AS avg_fare,
    ROUND(AVG("Surge Fee")::numeric, 2) AS avg_surge,
    ROUND(AVG(EXTRACT(EPOCH FROM ("Drop Off Time" - "Pickup Time")) / 60)::numeric, 2) AS avg_duration_min
FROM 
    public.trip
WHERE 
    passenger_count IS NOT NULL
GROUP BY 
    passenger_count
ORDER BY 
    passenger_count;

--Q14. TOTAL REVENUE(FARE + SURGE FEE ) BY LOCATIONS
SELECT 
    pl."Location" AS pickup_location,
    pl."City",
    ROUND(SUM(fare_amount + COALESCE("Surge Fee", 0)), 2) AS total_revenue,
    COUNT(*) AS trip_count
FROM 
    public.trip t
JOIN 
    public.location pl ON t."PULocationID" = pl."LocationID"
GROUP BY 
    pl."Location", pl."City"
ORDER BY 
    total_revenue desc
limit 20

--Q15. REVENUE BY TIME OF DAY
SELECT 
    CASE 
        WHEN EXTRACT(HOUR FROM "Pickup Time") BETWEEN 5 AND 11 THEN 'Morning'
        WHEN EXTRACT(HOUR FROM "Pickup Time") BETWEEN 12 AND 16 THEN 'Afternoon'
        WHEN EXTRACT(HOUR FROM "Pickup Time") BETWEEN 17 AND 21 THEN 'Evening'
        ELSE 'Night'
    END AS time_of_day,
    ROUND(SUM(fare_amount + COALESCE("Surge Fee", 0))::numeric, 2) AS total_revenue,
    COUNT(*) AS trip_count
FROM 
    public.trip
GROUP BY 
    time_of_day
ORDER BY 
    total_revenue DESC;

--Q16. REVENUE BY DAY OF WEEK 
SELECT 
    TO_CHAR("Pickup Time", 'Day') AS day_of_week,
    ROUND(SUM(fare_amount + COALESCE("Surge Fee", 0))::numeric, 2) AS total_revenue,
    COUNT(*) AS trip_count
FROM 
    public.trip
GROUP BY 
    day_of_week
ORDER BY 
    total_revenue DESC;


--Q.17 A NUMBER OF TRIPS PER ZONE PER HOUR (FOR DRIVER DEPLOYMENT)
SELECT 
    pl."Location" AS pickup_location,
    EXTRACT(HOUR FROM t."Pickup Time") AS hour,
    COUNT(*) AS trips_per_hour
FROM 
    public.trip t
JOIN 
    public.location pl ON t."PULocationID" = pl."LocationID"
GROUP BY 
    pl."Location", hour
ORDER BY 
    trips_per_hour DESC;

--Q18. ZONES WITH HIGH PICK UP BUT LOW DROP-OFFS
SELECT 
    l."Location",
    COALESCE(p.pickups, 0) AS total_pickups,
    COALESCE(d.dropoffs, 0) AS total_dropoffs,
    (COALESCE(p.pickups, 0) - COALESCE(d.dropoffs, 0)) AS pickup_drop_gap
FROM 
    public.location l
LEFT JOIN (
    SELECT "PULocationID", COUNT(*) AS pickups
    FROM public.trip
    GROUP BY "PULocationID"
) p ON l."LocationID" = p."PULocationID"
LEFT JOIN (
    SELECT "DOLocationID", COUNT(*) AS dropoffs
    FROM public.trip
    GROUP BY "DOLocationID"
) d ON l."LocationID" = d."DOLocationID"
ORDER BY 
    pickup_drop_gap DESC;


--Q19. PAYMENT COLLECTED BY CHANNELS
SELECT 
    "Payment_type",
    COUNT(*) AS trip_count,
    ROUND(SUM(fare_amount + COALESCE("Surge Fee", 0))::numeric, 2) AS total_revenue,
    ROUND(AVG(fare_amount + COALESCE("Surge Fee", 0))::numeric, 2) AS avg_revenue_per_trip
FROM 
    public.trip
GROUP BY 
    "Payment_type"
ORDER BY 
    total_revenue ASC;

--Q20 PAYMENT TYPE FREQUENCY PER DAY
SELECT 
    TO_CHAR("Pickup Time", 'YYYY-MM-DD') AS trip_date,
    "Payment_type",
    COUNT(*) AS trip_count
FROM 
    public.trip
GROUP BY 
    trip_date, "Payment_type"
ORDER BY 
    trip_date, trip_count DESC;

--Q21 TOP PICK UP DROP-OFF PAIRS BY FREQUENCY
SELECT 
    pl."Location" AS pickup_location,
    dl."Location" AS drop_location,
    pl."City" AS pickup_city,
    dl."City" AS drop_city,
    COUNT(*) AS trip_count,
    ROUND(AVG(trip_distance)::numeric, 2) AS avg_distance,
    ROUND(AVG(fare_amount + COALESCE("Surge Fee", 0))::numeric, 2) AS avg_total_fare
FROM 
    public.trip t
JOIN 
    public.location pl ON t."PULocationID" = pl."LocationID"
JOIN 
    public.location dl ON t."DOLocationID" = dl."LocationID"
GROUP BY 
    pl."Location", dl."Location", pl."City", dl."City"
ORDER BY 
    trip_count DESC
LIMIT 20;


--Q23. DISTANCE BASED TRIP CLUSTERING
SELECT 
    CASE 
        WHEN trip_distance < 2 THEN 'Very Short (0–2 km)'
        WHEN trip_distance BETWEEN 2 AND 5 THEN 'Short (2–5 km)'
        WHEN trip_distance BETWEEN 5 AND 10 THEN 'Medium (5–10 km)'
        WHEN trip_distance BETWEEN 10 AND 20 THEN 'Long (10–20 km)'
        ELSE 'Very Long (20+ km)'
    END AS distance_cluster,
    COUNT(*) AS trip_count,
    ROUND(AVG(fare_amount + COALESCE("Surge Fee", 0))::numeric, 2) AS avg_total_fare,
    ROUND(AVG(EXTRACT(EPOCH FROM ("Drop Off Time" - "Pickup Time")) / 60)::numeric, 2) AS avg_duration_min
FROM 
    public.trip
GROUP BY 
    distance_cluster
ORDER BY 
    trip_count DESC;

