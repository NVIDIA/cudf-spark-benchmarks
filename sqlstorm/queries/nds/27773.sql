
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        CAST('2002-10-01 12:34:56' AS TIMESTAMP) AS query_time,
        LENGTH(CONCAT(c.c_first_name, c.c_last_name)) AS total_name_length
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        cd.c_customer_sk,
        cd.full_name,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country,
        COALESCE(sd.total_spent, 0) AS total_spent,
        sd.order_count,
        cd.query_time,
        cd.total_name_length
    FROM CustomerData cd
    LEFT JOIN SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    ca_country,
    total_spent,
    order_count,
    query_time,
    total_name_length,
    CASE 
        WHEN total_spent > 1000 THEN 'High Value'
        WHEN total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM CombinedData
ORDER BY total_spent DESC
LIMIT 100;
