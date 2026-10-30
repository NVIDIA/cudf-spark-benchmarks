
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value,
        COUNT(DISTINCT ws.ws_ship_date_sk) AS unique_ship_dates
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        c.c_customer_id, ca.ca_city
),
top_cities AS (
    SELECT 
        ca.ca_city,
        SUM(ss.total_sales) AS city_total_sales,
        SUM(ss.total_orders) AS city_total_orders,
        AVG(ss.avg_order_value) AS avg_order_value
    FROM 
        sales_summary AS ss
    JOIN 
        customer AS c ON ss.c_customer_id = c.c_customer_id
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_city
    ORDER BY 
        city_total_sales DESC
    LIMIT 5
)
SELECT 
    tc.ca_city,
    tc.city_total_sales,
    tc.city_total_orders,
    tc.avg_order_value,
    COUNT(DISTINCT ss.c_customer_id) AS unique_customers
FROM 
    top_cities AS tc
JOIN 
    sales_summary AS ss ON tc.ca_city = ss.ca_city
GROUP BY 
    tc.ca_city, tc.city_total_sales, tc.city_total_orders, tc.avg_order_value
ORDER BY 
    tc.city_total_sales DESC;
