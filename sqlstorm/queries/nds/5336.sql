
WITH ranked_sales AS (
    SELECT 
        ws.ws_web_page_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_web_page_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_web_page_sk
),
top_sales AS (
    SELECT 
        wp.wp_web_page_id,
        wp.wp_creation_date_sk,
        rs.total_sales,
        rs.order_count
    FROM 
        ranked_sales rs
    JOIN 
        web_page wp ON rs.ws_web_page_sk = wp.wp_web_page_sk
    WHERE 
        rs.rank <= 10
)
SELECT 
    ts.wp_web_page_id,
    dd.d_date AS sales_date,
    ts.total_sales,
    ts.order_count
FROM 
    top_sales ts
CROSS JOIN 
    (SELECT d_date FROM date_dim ORDER BY d_date DESC LIMIT 1) dd
ORDER BY 
    ts.total_sales DESC;
