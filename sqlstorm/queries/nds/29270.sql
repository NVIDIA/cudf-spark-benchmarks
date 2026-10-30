
WITH AddressCounts AS (
    SELECT ca_state, 
           COUNT(*) AS address_count,
           SUM(LENGTH(ca_street_name)) AS total_street_name_length,
           AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM customer_address
    GROUP BY ca_state
),
CustomerDemoStatistics AS (
    SELECT cd_gender, 
           COUNT(*) AS demo_count, 
           MAX(cd_purchase_estimate) AS max_purchase_estimate, 
           MIN(cd_purchase_estimate) AS min_purchase_estimate
    FROM customer_demographics
    GROUP BY cd_gender
),
DateMetrics AS (
    SELECT d_year, 
           COUNT(*) AS total_dates, 
           COUNT(DISTINCT d_day_name) AS unique_days,
           SUM(CASE WHEN d_holiday = 'Y' THEN 1 ELSE 0 END) AS holiday_count
    FROM date_dim
    GROUP BY d_year
),
ItemDetails AS (
    SELECT i_category, 
           COUNT(*) AS item_count, 
           SUM(i_current_price) AS total_value, 
           AVG(i_current_price) AS avg_price,
           MAX(i_current_price) AS max_price,
           MIN(i_current_price) AS min_price
    FROM item
    GROUP BY i_category
)
SELECT ac.ca_state,
       ac.address_count,
       ac.total_street_name_length,
       ac.avg_street_name_length,
       cd.cd_gender,
       cd.demo_count,
       cd.max_purchase_estimate,
       cd.min_purchase_estimate,
       dm.d_year,
       dm.total_dates,
       dm.unique_days,
       dm.holiday_count,
       id.item_count,
       id.total_value,
       id.avg_price,
       id.max_price,
       id.min_price
FROM AddressCounts ac
JOIN CustomerDemoStatistics cd ON ac.address_count > 10
JOIN DateMetrics dm ON dm.total_dates > 1000
JOIN ItemDetails id ON id.item_count > 50
ORDER BY ac.ca_state, cd.cd_gender, dm.d_year, id.item_count DESC;
