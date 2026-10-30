
WITH  sales_analysis AS (
    SELECT 
        s.ss_sold_date_sk,
        s.ss_item_sk,
        SUM(s.ss_quantity) AS total_quantity,
        SUM(s.ss_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.ss_item_sk ORDER BY SUM(s.ss_net_paid) DESC) AS sales_rank
    FROM 
        store_sales s
    WHERE 
        s.ss_sold_date_sk BETWEEN (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022) AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
    GROUP BY 
        s.ss_sold_date_sk, s.ss_item_sk
    HAVING 
        SUM(s.ss_net_paid) > 1000
),
top_sales AS (
    SELECT 
        sales_analysis.ss_item_sk,
        sales_analysis.total_quantity,
        sales_analysis.total_sales,
        ROW_NUMBER() OVER (ORDER BY sales_analysis.total_sales DESC) as rank
    FROM 
        sales_analysis
    WHERE 
        sales_rank = 1
),
ship_modes AS (
    SELECT 
        ws.ws_item_sk,
        sm.sm_type,
        SUM(ws.ws_quantity) AS total_quantity_shipped
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        ws.ws_item_sk, sm.sm_type
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ts.total_quantity,
    ts.total_sales,
    COALESCE(sm.total_quantity_shipped, 0) AS total_quantity_shipped,
    CASE 
        WHEN ts.total_quantity > 0 THEN (ts.total_sales / ts.total_quantity)
        ELSE NULL 
    END AS average_sales_price
FROM 
    item i 
JOIN 
    top_sales ts ON i.i_item_sk = ts.ss_item_sk 
LEFT JOIN 
    ship_modes sm ON i.i_item_sk = sm.ws_item_sk 
WHERE 
    i.i_current_price IS NOT NULL
ORDER BY 
    ts.total_sales DESC
LIMIT 10;
