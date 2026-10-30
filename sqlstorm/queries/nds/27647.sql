
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
Benchmark AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        si.total_sales,
        si.order_count,
        CASE 
            WHEN si.total_sales IS NULL THEN 'No Sales'
            WHEN si.total_sales < 1000 THEN 'Low Value Customer'
            WHEN si.total_sales >= 1000 AND si.total_sales < 5000 THEN 'Medium Value Customer'
            ELSE 'High Value Customer'
        END AS customer_segment
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesData si ON ci.c_customer_sk = si.ws_bill_customer_sk
)
SELECT 
    customer_segment,
    COUNT(*) AS customer_count,
    AVG(total_sales) AS avg_sales,
    MAX(total_sales) AS max_sales
FROM 
    Benchmark
GROUP BY 
    customer_segment
ORDER BY 
    customer_segment;
