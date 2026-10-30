
WITH CustomerInfo AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        c.c_customer_sk
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
Benchmark AS (
    SELECT 
        ci.c_first_name,
        ci.c_last_name,
        ci.ca_city,
        ci.ca_state,
        si.total_sales,
        si.total_orders,
        CASE 
            WHEN si.total_sales IS NULL THEN 'No Sales'
            WHEN si.total_sales < 100 THEN 'Low Sales'
            WHEN si.total_sales >= 100 AND si.total_sales < 500 THEN 'Moderate Sales'
            ELSE 'High Sales'
        END AS sales_band
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesInfo si ON ci.c_customer_sk = si.customer_sk
)
SELECT 
    ca_state AS state,
    COUNT(*) AS customer_count,
    AVG(total_sales) AS average_sales,
    sales_band
FROM 
    Benchmark
GROUP BY 
    ca_state,
    sales_band
ORDER BY 
    state, 
    sales_band;
