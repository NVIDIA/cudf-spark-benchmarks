WITH  sales_cte AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
total_demos AS (
    SELECT
        cd_demo_sk,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer_demographics 
        JOIN customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY 
        cd_demo_sk
),
recent_returns AS (
    SELECT
        wr_item_sk,
        COUNT(wr_return_quantity) AS return_count
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2001) - 30
    GROUP BY 
        wr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(scte.total_sales, 0) AS total_sales,
    COALESCE(r.return_count, 0) AS recent_return_count,
    td.customer_count
FROM 
    item i
LEFT JOIN 
    sales_cte scte ON i.i_item_sk = scte.ws_item_sk
LEFT JOIN 
    recent_returns r ON i.i_item_sk = r.wr_item_sk
JOIN 
    total_demos td ON td.cd_demo_sk = i.i_item_sk % 10 
WHERE 
    (i.i_current_price - COALESCE(r.return_count, 0) * 0.5) > 10 
    AND (i.i_formulation IS NOT NULL AND i.i_color IS NOT NULL)
ORDER BY 
    total_sales DESC, 
    recent_return_count ASC
LIMIT 100;