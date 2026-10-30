
WITH CustomerInfo AS (
    SELECT c.c_customer_sk, 
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_education_status, 
           c.c_email_address, 
           ca.ca_city, 
           ca.ca_state,
           LENGTH(c.c_email_address) AS email_length,
           CHAR_LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS name_length
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state IN ('CA', 'NY', 'TX')
),
SalesAnalysis AS (
    SELECT ws.ws_bill_customer_sk, 
           SUM(ws.ws_sales_price) AS total_sales,
           SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
FullAnalysis AS (
    SELECT ci.full_name, 
           ci.cd_gender, 
           ci.cd_marital_status, 
           sa.total_sales, 
           sa.total_quantity, 
           ci.email_length, 
           ci.name_length
    FROM CustomerInfo ci
    LEFT JOIN SalesAnalysis sa ON ci.c_customer_sk = sa.ws_bill_customer_sk
)
SELECT fa.*,
       CASE 
           WHEN fa.total_sales > 1000 THEN 'High Value Customer'
           WHEN fa.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
           ELSE 'Low Value Customer'
       END AS customer_value_category
FROM FullAnalysis fa
ORDER BY fa.total_sales DESC, fa.full_name;
