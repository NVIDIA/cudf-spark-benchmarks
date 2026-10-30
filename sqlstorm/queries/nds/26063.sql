
WITH AddressCounts AS (
    SELECT ca_state,
           ca_city,
           COUNT(DISTINCT ca_address_sk) AS total_addresses,
           STRING_AGG(ca_street_name, ', ') AS street_names,
           STRING_AGG(ca_street_type, ', ') AS street_types
    FROM customer_address
    GROUP BY ca_state, ca_city
),
DemographicStats AS (
    SELECT d.d_year,
           d.d_month_seq,
           SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
           SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
           AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM date_dim d
    JOIN customer c ON d.d_date_sk = c.c_first_sales_date_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY d.d_year, d.d_month_seq
),
SalesInfo AS (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_quantity) AS total_sold,
           SUM(ws.ws_sales_price) AS total_sales
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
)
SELECT ac.ca_state,
       ac.ca_city,
       ac.total_addresses,
       ac.street_names,
       ac.street_types,
       ds.d_year,
       ds.d_month_seq,
       ds.male_count,
       ds.female_count,
       ds.avg_purchase_estimate,
       si.total_sold,
       si.total_sales
FROM AddressCounts ac
JOIN DemographicStats ds ON ac.ca_state = CAST(ds.d_year AS STRING)
JOIN SalesInfo si ON ac.total_addresses > 100  
ORDER BY ac.ca_state, ac.ca_city, ds.d_year, ds.d_month_seq;
