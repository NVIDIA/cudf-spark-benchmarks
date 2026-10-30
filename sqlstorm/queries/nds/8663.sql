
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_name,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2001 AND 
        d.d_moy IN (6, 7)  
    GROUP BY 
        w.w_warehouse_name
),
demographics AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990    
)
SELECT 
    s.w_warehouse_name,
    s.total_quantity_sold,
    s.total_sales,
    s.total_discount,
    s.total_orders,
    d.c_first_name,
    d.c_last_name,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_credit_rating,
    d.ca_city,
    d.ca_state
FROM 
    sales_summary s
JOIN 
    demographics d ON d.ca_city = 'New York'  
ORDER BY 
    s.total_sales DESC
LIMIT 10;
