
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COALESCE(LEFT(c.c_email_address, 20), 'N/A') AS email_prefix
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_net_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
AggregatedCustomerSales AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        COALESCE(sd.total_net_sales, 0) AS total_net_sales,
        COALESCE(sd.order_count, 0) AS order_count,
        ROUND(COALESCE(sd.total_net_sales / NULLIF(sd.order_count, 0), 0), 2) AS average_order_value
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN average_order_value > 100 THEN 'High Value'
        WHEN average_order_value BETWEEN 50 AND 100 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    AggregatedCustomerSales
WHERE 
    ca_city IS NOT NULL
ORDER BY 
    total_net_sales DESC
LIMIT 100;
