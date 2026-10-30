
WITH CustomerLocation AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
SalesStats AS (
    SELECT 
        cl.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        CustomerLocation cl
    JOIN 
        web_sales ws ON cl.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        cl.c_customer_sk
), 
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cl.c_customer_sk
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        CustomerLocation cl ON cl.c_customer_sk = c.c_customer_sk
)
SELECT 
    cl.full_name,
    cl.ca_city,
    cl.ca_state,
    cl.ca_country,
    ds.cd_gender,
    ds.cd_marital_status,
    ds.cd_education_status,
    ss.total_orders,
    ss.total_spent
FROM 
    CustomerLocation cl
LEFT JOIN 
    SalesStats ss ON cl.c_customer_sk = ss.c_customer_sk
LEFT JOIN 
    Demographics ds ON cl.c_customer_sk = ds.c_customer_sk
WHERE 
    ss.total_spent > 0
ORDER BY 
    ss.total_spent DESC
LIMIT 50;
