/* Average Leadtime per City */

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
WHERE rn = 1

/* Top 5 Fastest Tracking Number and Top 5 Slowest Tracking Number */

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
ORDER BY lto.leadtime_asc