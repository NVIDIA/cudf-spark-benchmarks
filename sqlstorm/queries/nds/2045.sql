
WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
top_sales AS (
    SELECT 
        s.ws_sold_date_sk,
        s.ws_item_sk,
        s.total_quantity,
        s.total_sales
    FROM 
        sales_summary s
    WHERE 
        s.sales_rank <= 5
)
SELECT 
    d.d_date AS sale_date,
    i.i_item_id,
    i.i_product_name,
    COALESCE(ts.total_quantity, 0) AS total_quantity,
    COALESCE(ts.total_sales, 0) AS total_sales,
    CASE 
        WHEN ts.total_sales > 1000 THEN 'High Revenue'
        WHEN ts.total_sales BETWEEN 500 AND 1000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    date_dim d
LEFT JOIN 
    top_sales ts ON d.d_date_sk = ts.ws_sold_date_sk
JOIN 
    item i ON ts.ws_item_sk = i.i_item_sk
WHERE 
    d.d_year = 2022
    AND d.d_month_seq IN (5, 6, 7)
ORDER BY 
    d.d_date, total_sales DESC;
