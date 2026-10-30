
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        (SELECT COUNT(*) FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk) AS total_web_sales,
        (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = c.c_customer_sk) AS total_store_sales
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesAggregates AS (
    SELECT 
        ci.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales_value,
        SUM(ss.ss_ext_sales_price) AS total_store_sales_value
    FROM CustomerInfo ci
    LEFT JOIN web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_sales ss ON ci.c_customer_sk = ss.ss_customer_sk
    GROUP BY ci.c_customer_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    COALESCE(sa.total_web_sales_value, 0) AS total_web_sales_value,
    COALESCE(sa.total_store_sales_value, 0) AS total_store_sales_value,
    (COALESCE(sa.total_web_sales_value, 0) + COALESCE(sa.total_store_sales_value, 0)) AS total_combined_sales
FROM CustomerInfo ci
LEFT JOIN SalesAggregates sa ON ci.c_customer_sk = sa.c_customer_sk
WHERE (ci.cd_gender = 'F' AND ci.cd_marital_status = 'M')
  OR (ci.cd_gender = 'M' AND ci.cd_marital_status = 'S')
ORDER BY total_combined_sales DESC
LIMIT 100;
