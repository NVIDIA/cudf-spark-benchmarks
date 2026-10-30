
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS average_profit,
        COUNT(DISTINCT ws.ws_ship_mode_sk) AS distinct_ship_modes
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        ss.total_sales,
        ss.order_count,
        ss.average_profit,
        ss.distinct_ship_modes,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        sales_summary ss
    JOIN 
        customer c ON ss.c_customer_id = c.c_customer_id
    WHERE 
        ss.total_sales > 1000
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.order_count,
    tc.average_profit,
    tc.distinct_ship_modes,
    tc.sales_rank,
    ca.ca_city,
    ca.ca_state
FROM 
    top_customers tc
JOIN 
    customer_address ca ON tc.c_customer_id = ca.ca_address_id
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.sales_rank;
