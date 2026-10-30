
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        REPLACE(LOWER(c.c_email_address), '@', ' [at] ') AS formatted_email,
        a.ca_city,
        a.ca_state,
        a.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
),
TransactionInfo AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
Result AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.formatted_email,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        COALESCE(ti.total_quantity, 0) AS total_quantity,
        COALESCE(ti.total_sales, 0) AS total_sales,
        COALESCE(ti.total_orders, 0) AS total_orders
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        TransactionInfo ti ON ci.c_customer_sk = ti.ws_bill_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    formatted_email,
    ca_city,
    ca_state,
    ca_country,
    total_quantity,
    total_sales,
    total_orders,
    CASE 
        WHEN total_sales > 500 THEN 'High Value Customer'
        WHEN total_sales BETWEEN 100 AND 500 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_segment
FROM 
    Result
ORDER BY 
    total_sales DESC
LIMIT 100;
