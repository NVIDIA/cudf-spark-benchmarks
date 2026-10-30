
WITH CustomerDetails AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_marital_status, 
           ca.ca_city, ca.ca_state, ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesDetails AS (
    SELECT DISTINCT ws.ws_item_sk, ws.ws_bill_customer_sk, ws.ws_sales_price,
           cast(d.d_date as STRING) AS sold_date, ws.ws_order_number
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE ws.ws_sales_price > 0
),
Summary AS (
    SELECT CD.c_customer_sk, 
           COUNT(SD.ws_order_number) AS total_orders,
           SUM(SD.ws_sales_price) AS total_spent,
           MAX(SD.sold_date) AS last_order_date
    FROM CustomerDetails CD
    LEFT JOIN SalesDetails SD ON CD.c_customer_sk = SD.ws_bill_customer_sk
    GROUP BY CD.c_customer_sk
)
SELECT CD.c_first_name, 
       CD.c_last_name, 
       CD.ca_city, 
       CD.ca_state, 
       CD.ca_country, 
       S.total_orders, 
       S.total_spent, 
       S.last_order_date
FROM CustomerDetails CD
JOIN Summary S ON CD.c_customer_sk = S.c_customer_sk
WHERE S.total_orders >= 5 
ORDER BY S.total_spent DESC, S.last_order_date DESC;
