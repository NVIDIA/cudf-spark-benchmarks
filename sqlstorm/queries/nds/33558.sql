
WITH  Sales_CTE AS (
    SELECT ws_sold_date_sk, ws_item_sk, ws_quantity, ws_net_profit, 
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
Top_Sales AS (
    SELECT ws_item_sk, SUM(ws_quantity) AS total_quantity_sold, SUM(ws_net_profit) AS total_net_profit
    FROM Sales_CTE
    WHERE rn <= 10
    GROUP BY ws_item_sk
),
Customer_Avg AS (
    SELECT c_customer_sk, AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY c_customer_sk
),
Join_Customer AS (
    SELECT t.total_quantity_sold, t.total_net_profit, ca.ca_city, ca.ca_state,
           COALESCE(cd.avg_purchase_estimate, 0) AS avg_purchase_estimate
    FROM Top_Sales t
    LEFT JOIN customer c ON c.c_first_shipto_date_sk = (SELECT MIN(c_first_shipto_date_sk) FROM customer)
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN Customer_Avg cd ON c.c_customer_sk = cd.c_customer_sk
)
SELECT r.r_reason_desc, j.total_quantity_sold, j.total_net_profit, j.ca_city, j.ca_state, j.avg_purchase_estimate
FROM Join_Customer j
JOIN reason r ON j.total_quantity_sold > 100
WHERE j.total_net_profit IS NOT NULL AND j.ca_state IN ('NY', 'CA') 
ORDER BY j.total_net_profit DESC
LIMIT 100;
