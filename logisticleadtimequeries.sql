/* 1. Average Leadtime per City */

WITH leadtimePerCity AS(
	SELECT 
		Destination_City,
		tracking_number,
		CAST(order_creation_ts AS DATE) oc_date,
		DATEDIFF(SECOND, order_creation_ts, delivered_ts) / 3600.0 leadtime
	FROM SalesDb.dbo.TechnicalTest
	WHERE delivered_ts IS NOT NULL
),
averageLeadtime AS(
	SELECT *,
		AVG(leadtime) OVER(PARTITION BY Destination_City, oc_date) avg_leadtime,
		ROW_NUMBER() OVER (PARTITION BY Destination_City, oc_date ORDER BY leadtime ASC) rn
	FROM leadtimePerCity
)
SELECT 
	alt.oc_date,
	alt.Destination_City,
	ROUND(alt.avg_leadtime, 1) average_leadtime_hh,
	alt.tracking_number fastest_tracking_number
FROM averageLeadtime alt
WHERE rn = 1;

/* 2. Top 5 Fastest Tracking Number and Top 5 Slowest Tracking Number */

WITH leadtime_unordered AS(
	SELECT 
		tracking_number,
		CAST(order_creation_ts AS DATE) oc_date,
		CAST(delivered_ts AS DATE) delivered_date,
		DATEDIFF(SECOND, order_creation_ts, delivered_ts) / 3600.0 leadtime
	FROM SalesDb.dbo.TechnicalTest
	WHERE delivered_ts IS NOT NULL
),
leadtime_ordered AS(
	SELECT 
		*,
		ROW_NUMBER() OVER (ORDER BY leadtime ASC) leadtime_asc,
		ROW_NUMBER() OVER (ORDER BY leadtime DESC) leadtime_desc
	FROM leadtime_unordered
)
SELECT 
	lto.tracking_number,
	lto.oc_date,
	lto.delivered_date,
	lto.leadtime,
	lto.leadtime_asc
FROM leadtime_ordered lto
WHERE lto.leadtime_asc BETWEEN 1 AND 5 OR lto.leadtime_desc between 1 AND 5
ORDER BY lto.leadtime_asc;

/* 3. Delivery-time Distribution in Histogram Buckets */

SELECT
    CASE 
        WHEN leadtime_hh < 12 THEN '< 12 Hours'
        WHEN leadtime_hh < 24 THEN '12-24 Hours'
        WHEN leadtime_hh < 48 THEN '24-48 Hours'
        ELSE '> 48 Hours'
    END AS leadtime_bucket,
    COUNT(*) AS orders_count
FROM (
    SELECT 
        tracking_number,
        DATEDIFF(SECOND, order_creation_ts, delivered_ts) / 3600.0 AS leadtime_hh
    FROM SalesDb.dbo.TechnicalTest
) AS t
GROUP BY
    CASE 
        WHEN leadtime_hh < 12 THEN '< 12 Hours'
        WHEN leadtime_hh < 24 THEN '12-24 Hours'
        WHEN leadtime_hh < 48 THEN '24-48 Hours'
        ELSE '> 48 Hours'
    END
ORDER BY MIN(leadtime_hh);

/* 4. Lead Time Trends Over Time */
SELECT
    CAST(order_creation_ts AS DATE) AS order_date,
    ROUND(AVG(DATEDIFF(SECOND, order_creation_ts, delivered_ts) / 3600.0), 2) AS avg_leadtime_hh
FROM SalesDb.dbo.TechnicalTest
GROUP BY CAST(order_creation_ts AS DATE)
ORDER BY order_date;

/* 5. Best/Worst Performing Destination Cities */

SELECT
    destination_city,
    ROUND(AVG(DATEDIFF(SECOND, order_creation_ts, delivered_ts) / 3600.0), 1) AS avg_leadtime_hh
FROM SalesDb.dbo.TechnicalTest
GROUP BY destination_city
ORDER BY avg_leadtime_hh ASC;