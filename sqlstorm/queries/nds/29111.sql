
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS sales_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
benchmark_data AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.sales_count, 0) AS sales_count,
        CASE 
            WHEN COALESCE(sd.total_sales, 0) = 0 THEN 'No Sales'
            WHEN COALESCE(sd.total_sales, 0) < 100 THEN 'Low Sales'
            WHEN COALESCE(sd.total_sales, 0) BETWEEN 100 AND 500 THEN 'Average Sales'
            ELSE 'High Sales'
        END AS sales_category
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_data sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    ca_country,
    total_sales,
    sales_count,
    sales_category
FROM 
    benchmark_data
ORDER BY 
    total_sales DESC, 
    sales_count DESC
LIMIT 100;
