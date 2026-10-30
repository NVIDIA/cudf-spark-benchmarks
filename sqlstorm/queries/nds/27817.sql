
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
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
sales_info AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    COALESCE(si.total_sales, 0) AS total_sales,
    COALESCE(si.total_orders, 0) AS total_orders,
    CASE 
        WHEN COALESCE(si.total_sales, 0) >= 1000 THEN 'High Value'
        WHEN COALESCE(si.total_sales, 0) >= 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    customer_info ci
LEFT JOIN 
    sales_info si ON ci.c_customer_sk = si.ws_bill_customer_sk
WHERE 
    ci.ca_state = 'CA'
ORDER BY 
    total_sales DESC;
