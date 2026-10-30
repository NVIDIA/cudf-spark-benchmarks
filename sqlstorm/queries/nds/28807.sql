
WITH summary AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        d.d_year,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year >= 2020
    GROUP BY 
        c.c_first_name, 
        c.c_last_name, 
        ca.ca_city, 
        ca.ca_state, 
        d.d_year
),
ranked AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY ca_city ORDER BY total_sales DESC) AS sales_rank
    FROM 
        summary
)
SELECT 
    r.c_first_name,
    r.c_last_name,
    r.ca_city,
    r.ca_state,
    r.d_year,
    r.total_orders,
    r.total_sales
FROM 
    ranked r
WHERE 
    r.sales_rank <= 5
ORDER BY 
    r.ca_city, 
    r.total_sales DESC;
