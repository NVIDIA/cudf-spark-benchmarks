
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
),
average_sales AS (
    SELECT 
        ws_item_sk, 
        AVG(ws_sales_price) AS avg_sales_price 
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
),
high_volume_returns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returns
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk 
    HAVING 
        SUM(cr_return_quantity) > 100
),
final_selection AS (
    SELECT 
        r.ws_item_sk,
        r.ws_sales_price,
        r.ws_quantity,
        a.avg_sales_price,
        COALESCE(hvr.total_returns, 0) AS total_returns
    FROM 
        ranked_sales r
    LEFT JOIN 
        average_sales a ON r.ws_item_sk = a.ws_item_sk
    LEFT JOIN 
        high_volume_returns hvr ON r.ws_item_sk = hvr.cr_item_sk
    WHERE 
        r.price_rank = 1
)
SELECT 
    fs.ws_item_sk,
    fs.ws_sales_price,
    fs.ws_quantity,
    fs.avg_sales_price,
    fs.total_returns,
    CASE 
        WHEN fs.total_returns = 0 THEN 'No Returns'
        WHEN fs.total_returns > 50 THEN 'High Return Rate'
        ELSE 'Normal Return Rate' 
    END AS return_rate_status
FROM 
    final_selection fs
WHERE 
    fs.ws_sales_price > (SELECT AVG(ws_sales_price) FROM web_sales)
    OR fs.total_returns IS NULL
ORDER BY 
    fs.ws_item_sk;
