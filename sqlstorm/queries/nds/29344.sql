
WITH CustomerDetail AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesDetail AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        ci.full_name,
        ci.ca_city,
        ci.ca_state
    FROM 
        web_sales ws
    JOIN 
        CustomerDetail ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    GROUP BY 
        ws.ws_order_number, ci.full_name, ci.ca_city, ci.ca_state
),
SalesStats AS (
    SELECT 
        full_name,
        ca_city,
        ca_state,
        COUNT(ws_order_number) AS total_orders,
        SUM(total_sales) AS total_revenue,
        AVG(total_quantity) AS avg_quantity_per_order
    FROM 
        SalesDetail
    GROUP BY 
        full_name, ca_city, ca_state
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    total_orders,
    total_revenue,
    avg_quantity_per_order,
    CASE 
        WHEN total_revenue > 1000 THEN 'High Value Customer'
        WHEN total_revenue BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_category
FROM 
    SalesStats
ORDER BY 
    total_revenue DESC, full_name;
