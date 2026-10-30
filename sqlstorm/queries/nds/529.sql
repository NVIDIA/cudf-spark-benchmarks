
WITH ranked_sales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rank_sales
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 50
), total_returns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
), item_details AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price,
        COALESCE(total_returns.total_returned, 0) AS total_returned,
        (CASE 
            WHEN i_current_price < 20 THEN 'Low Price'
            WHEN i_current_price BETWEEN 20 AND 50 THEN 'Medium Price'
            ELSE 'High Price'
        END) AS price_band
    FROM 
        item
    LEFT JOIN 
        total_returns ON item.i_item_sk = total_returns.sr_item_sk
)
SELECT 
    DISTINCT id.i_item_desc,
    id.i_current_price,
    id.total_returned,
    id.price_band,
    rs.ws_quantity,
    rs.ws_sales_price
FROM 
    item_details id
JOIN 
    ranked_sales rs ON id.i_item_sk = rs.ws_item_sk
WHERE 
    id.price_band = 'Medium Price'
    AND rs.rank_sales <= 5
    AND rs.ws_quantity IS NOT NULL
ORDER BY 
    id.total_returned DESC, 
    rs.ws_sales_price DESC
LIMIT 100
