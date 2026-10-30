
WITH filtered_customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag, 
           cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_credit_rating ORDER BY c.c_birth_year DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating IN ('Good', 'Excellent') 
      AND c.c_birth_year < 1970
      AND c.c_first_name IS NOT NULL
),
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM web_sales ws
    INNER JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year >= 2020
    GROUP BY ws.ws_item_sk
),
top_sales AS (
    SELECT fs.c_customer_sk, fs.c_first_name, fs.c_last_name, fs.c_preferred_cust_flag,
           fs.cd_gender, fs.cd_marital_status, fs.cd_credit_rating,
           sd.total_quantity, sd.total_sales, sd.avg_net_profit
    FROM filtered_customers fs
    LEFT JOIN sales_data sd ON fs.c_customer_sk IN (
        SELECT DISTINCT ws.ws_bill_customer_sk
        FROM web_sales ws
        JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
        WHERE dd.d_year >= 2020
     )
    WHERE fs.rn = 1
)
SELECT tc.c_first_name, tc.c_last_name, tc.cd_gender, tc.total_quantity, 
       COALESCE(tc.total_sales, 0) AS total_sales, 
       COALESCE(tc.avg_net_profit, 0) AS avg_net_profit,
       CASE 
           WHEN COALESCE(tc.total_sales, 0) = 0 THEN 'No Sales' 
           ELSE 'Has Sales' 
       END AS sales_status
FROM top_sales tc
RIGHT JOIN customer_address ca ON tc.c_customer_sk = ca.ca_address_sk
WHERE ca.ca_state = 'NY' 
  AND (tc.cd_gender IS NULL OR tc.cd_gender = 'F')
  AND (tc.total_quantity IS NULL OR tc.total_quantity >= 10)
ORDER BY sales_status DESC, total_sales DESC;
