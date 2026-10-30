
WITH sales_summary AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_revenue,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
        AND i.i_current_price > 20.00
    GROUP BY 
        d.d_year, d.d_month_seq
), avg_revenue AS (
    SELECT 
        d_year,
        AVG(total_revenue) AS avg_revenue
    FROM 
        sales_summary
    GROUP BY 
        d_year
), max_revenue AS (
    SELECT 
        d_year,
        MAX(total_revenue) AS max_revenue
    FROM 
        sales_summary
    GROUP BY 
        d_year
)
SELECT 
    a.d_year,
    a.avg_revenue,
    m.max_revenue,
    (m.max_revenue - a.avg_revenue) AS revenue_gap
FROM 
    avg_revenue a
JOIN 
    max_revenue m ON a.d_year = m.d_year
ORDER BY 
    a.d_year;
