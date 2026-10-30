
WITH CustomerInfo AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        c.c_current_cdemo_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ws.ws_bill_cdemo_sk
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_cdemo_sk
),
CombinedData AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        sd.total_quantity,
        sd.total_sales,
        sd.total_orders
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesData sd ON ci.c_current_cdemo_sk = sd.ws_bill_cdemo_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    COALESCE(total_quantity, 0) AS total_quantity,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(total_orders, 0) AS total_orders,
    CASE 
        WHEN COALESCE(total_sales, 0) > 1000 THEN 'High Value'
        WHEN COALESCE(total_sales, 0) BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    CombinedData
ORDER BY 
    total_sales DESC
LIMIT 100;
