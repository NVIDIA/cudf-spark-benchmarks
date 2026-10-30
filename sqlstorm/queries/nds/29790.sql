
WITH customer_info AS (
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
        LEFT(c.c_email_address, POSITION('@' IN c.c_email_address) - 1) AS email_name
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
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
final_data AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        sd.total_sales,
        sd.total_orders,
        sd.total_sales / NULLIF(sd.total_orders, 0) AS avg_order_value
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_data sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    fd.full_name,
    fd.ca_city,
    fd.ca_state,
    COALESCE(fd.total_sales, 0) AS total_sales,
    COALESCE(fd.total_orders, 0) AS total_orders,
    COALESCE(fd.avg_order_value, 0) AS avg_order_value
FROM 
    final_data fd
WHERE 
    COALESCE(fd.total_sales, 0) > 1000
ORDER BY 
    fd.avg_order_value DESC;
