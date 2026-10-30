
WITH  sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
                             AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_bill_customer_sk
),
filtered_demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate > 5000
        AND cd_gender IS NOT NULL
)
SELECT 
    ca.ca_city,
    SUM(ss.total_sales) AS total_city_sales,
    COUNT(ss.order_count) AS customer_count,
    AVG(fd.cd_purchase_estimate) AS avg_purchase_estimate,
    MAX(fd.cd_dep_count) AS max_dep_count
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    sales_summary ss ON ss.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN 
    filtered_demographics fd ON fd.cd_demo_sk = c.c_current_cdemo_sk
WHERE 
    ca.ca_state = 'CA'
GROUP BY 
    ca.ca_city
HAVING 
    SUM(ss.total_sales) > 10000
ORDER BY 
    total_city_sales DESC
LIMIT 10;
