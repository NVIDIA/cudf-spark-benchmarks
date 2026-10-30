
WITH  IncomeBands AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound, 
           CASE 
               WHEN ib_lower_bound IS NULL THEN 'Unknown'
               WHEN ib_upper_bound IS NULL THEN 'Infinity'
               ELSE '$' || ib_lower_bound || ' - $' || ib_upper_bound
           END AS income_range
    FROM income_band
    WHERE ib_lower_bound IS NOT NULL OR ib_upper_bound IS NOT NULL
),
SalesData AS (
    SELECT 
        ws_item_sk,
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS item_rank
    FROM web_sales
    GROUP BY ws_item_sk, ws_sold_date_sk
),
CustomerStatistics AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT cd_demo_sk) AS distinct_demo_count,
        MAX(cd_purchase_estimate) AS max_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    ib.income_range,
    SUM(sd.total_quantity) AS total_sales_quantity,
    COUNT(DISTINCT cs.c_customer_sk) AS unique_customers,
    AVG(cs.max_estimate) AS avg_purchase_estimate
FROM customer_address ca
JOIN store s ON ca.ca_address_sk = s.s_store_sk
LEFT JOIN SalesData sd ON sd.ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_category_id = 5)
LEFT JOIN CustomerStatistics cs ON cs.c_customer_sk = sd.ws_item_sk
LEFT JOIN IncomeBands ib ON cs.max_estimate BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
WHERE ca.ca_state IS NOT NULL
AND ca.ca_city IS NOT NULL
AND (ib.ib_upper_bound IS NULL OR ib.ib_lower_bound IS NOT NULL)
GROUP BY ca.ca_city, ca.ca_state, ib.income_range
HAVING SUM(sd.total_profit) > 10000
ORDER BY total_sales_quantity DESC
LIMIT 100 OFFSET 10;
