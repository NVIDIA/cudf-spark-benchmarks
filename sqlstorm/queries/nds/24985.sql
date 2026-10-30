
WITH RecursiveCustomerCTE AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_birth_month, c_birth_year,
           ROW_NUMBER() OVER (PARTITION BY c_birth_month ORDER BY c_birth_year DESC) AS rn
    FROM customer
    WHERE c_birth_month IS NOT NULL
),
FilteredSales AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) AS total_quantity,
           AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
    HAVING SUM(ws.ws_quantity) > 10
),
TotalReturns AS (
    SELECT sr_item_sk, SUM(sr_return_quantity) AS total_return_quantity
    FROM store_returns
    GROUP BY sr_item_sk
)
SELECT CA.ca_city, CA.ca_state, CC.c_first_name, CC.c_last_name,
       COALESCE(TS.total_quantity, 0) AS total_sales,
       COALESCE(TR.total_return_quantity, 0) AS total_returns,
       (COALESCE(TS.total_quantity, 0) - COALESCE(TR.total_return_quantity, 0)) AS net_sales,
       RANK() OVER (PARTITION BY CA.ca_state ORDER BY (COALESCE(TS.total_quantity, 0) - COALESCE(TR.total_return_quantity, 0)) DESC) AS city_rank,
       CASE 
           WHEN CA.ca_country IS NULL THEN 'Unknown Country'
           ELSE CA.ca_country
       END AS country_info
FROM customer_address CA
LEFT JOIN customer CC ON CA.ca_address_sk = CC.c_current_addr_sk
LEFT JOIN FilteredSales TS ON TS.ws_item_sk = CC.c_customer_sk
LEFT JOIN TotalReturns TR ON TR.sr_item_sk = CC.c_customer_sk
WHERE CA.ca_state IN ('NY', 'CA')
AND (CC.c_birth_year < 1980 OR CC.c_birth_year IS NULL)
ORDER BY city_rank, CA.ca_city;
