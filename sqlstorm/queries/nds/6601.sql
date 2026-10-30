
WITH aggregated_sales AS (
    SELECT 
        ws.ws_web_page_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_web_page_sk
),

top_sales AS (
    SELECT 
        ag.ws_web_page_sk,
        ag.total_quantity,
        ag.total_net_paid,
        ag.avg_sales_price,
        ROW_NUMBER() OVER (ORDER BY ag.total_net_paid DESC) AS rank
    FROM 
        aggregated_sales ag
)

SELECT 
    wp.wp_url,
    wp.wp_type,
    ts.total_quantity,
    ts.total_net_paid,
    ts.avg_sales_price
FROM 
    top_sales ts
JOIN 
    web_page wp ON ts.ws_web_page_sk = wp.wp_web_page_sk
WHERE 
    ts.rank <= 10
ORDER BY 
    ts.total_net_paid DESC;
