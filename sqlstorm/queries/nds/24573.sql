
WITH  AddressHierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, 
           ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS city_rank
    FROM customer_address
    WHERE ca_city IS NOT NULL
),
IncomeRange AS (
    SELECT DISTINCT 
        hd_demo_sk, 
        CASE 
            WHEN ib_lower_bound IS NULL THEN 'Unknown'
            WHEN ib_upper_bound IS NULL THEN 'Infinity'
            ELSE CONCAT(ib_lower_bound, ' to ', ib_upper_bound)
        END AS income_range
    FROM household_demographics h
    LEFT JOIN income_band i ON h.hd_income_band_sk = i.ib_income_band_sk
),
SalesData AS (
    SELECT ws_sold_date_sk, ws_item_sk, ws_quantity, ws_sales_price, 
           SUM(ws_sales_price * ws_quantity) OVER (PARTITION BY ws_item_sk 
           ORDER BY ws_sold_date_sk) AS cumulative_sales,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS sales_rank
    FROM web_sales
    WHERE ws_quantity > 0
),
FilteredReturns AS (
    SELECT cr_item_sk, 
           SUM(cr_return_quantity) AS total_returned,
           COUNT(DISTINCT cr_order_number) AS orders_returned
    FROM catalog_returns
    GROUP BY cr_item_sk
    HAVING SUM(cr_return_quantity) > 0
)
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    a.ca_city AS address_city,
    a.ca_state AS address_state,
    i.income_range,
    COALESCE(SUM(sd.cumulative_sales), 0) AS total_sales,
    COALESCE(SUM(fr.total_returned), 0) AS total_returns,
    COUNT(DISTINCT ah.city_rank) AS unique_cities
FROM customer c
JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN IncomeRange i ON c.c_current_cdemo_sk = i.hd_demo_sk
LEFT JOIN SalesData sd ON c.c_customer_sk = sd.ws_item_sk
LEFT JOIN FilteredReturns fr ON sd.ws_item_sk = fr.cr_item_sk
LEFT JOIN AddressHierarchy ah ON a.ca_city = ah.ca_city AND a.ca_state = ah.ca_state
WHERE c.c_birth_month = 2 AND c.c_birth_day IS NULL
GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, a.ca_city, a.ca_state, i.income_range
HAVING COUNT(DISTINCT ah.city_rank) > 1 
   OR SUM(fr.total_returned) > (SELECT AVG(total_returned) FROM FilteredReturns)
ORDER BY total_sales DESC NULLS LAST;
