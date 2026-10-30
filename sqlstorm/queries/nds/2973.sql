WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws 
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451371 AND 2451445  
),
total_sales AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns 
    GROUP BY 
        sr_item_sk
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(ts.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(ts.total_return_amt, 0) AS total_return_amt,
        (i.i_current_price * ws.ws_quantity - COALESCE(ts.total_return_amt, 0)) AS net_sales
    FROM 
        item i
    LEFT JOIN total_sales ts ON i.i_item_sk = ts.sr_item_sk
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
)
SELECT 
    id.i_item_sk,
    id.i_item_desc,
    id.i_current_price,
    SUM(id.net_sales) AS total_net_sales,
    AVG(id.i_current_price) AS avg_price,
    MAX(id.total_return_quantity) AS max_return_quantity,
    COUNT(DISTINCT r.price_rank) AS unique_price_counts
FROM 
    item_details id
JOIN ranked_sales r ON id.i_item_sk = r.ws_item_sk
GROUP BY 
    id.i_item_sk, 
    id.i_item_desc, 
    id.i_current_price
HAVING 
    SUM(id.net_sales) > 1000  
ORDER BY 
    total_net_sales DESC
LIMIT 50;