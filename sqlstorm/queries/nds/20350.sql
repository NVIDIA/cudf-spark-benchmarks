
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank_price,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.ws_item_sk) AS total_net_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450600
    AND
        ws.ws_quantity > 0
),
filtered_returns AS (
    SELECT 
        wr.wr_item_sk,
        wr.wr_order_number,
        SUM(wr.wr_return_quantity) AS total_returns,
        COUNT(wr.wr_order_number) AS return_count
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk, 
        wr.wr_order_number
    HAVING 
        SUM(wr.wr_return_quantity) > 1
),
integrated_sales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        COALESCE(SUM(sales.ws_quantity), 0) AS total_sold,
        COALESCE(SUM(returns.total_returns), 0) AS total_returned,
        (COALESCE(SUM(sales.ws_quantity), 0) - COALESCE(SUM(returns.total_returns), 0)) AS net_sales,
        SUM(sales.ws_net_profit) AS total_profit
    FROM 
        item 
    LEFT JOIN 
        web_sales sales ON item.i_item_sk = sales.ws_item_sk
    LEFT JOIN 
        filtered_returns returns ON sales.ws_item_sk = returns.wr_item_sk AND sales.ws_order_number = returns.wr_order_number
    GROUP BY 
        item.i_item_id, 
        item.i_product_name
)
SELECT 
    isales.i_item_id,
    isales.i_product_name,
    isales.total_sold,
    isales.total_returned,
    isales.net_sales,
    isales.total_profit,
    NULLIF(COALESCE(ranked.rank_price, 0), 0) AS highest_price_rank
FROM 
    integrated_sales isales
LEFT JOIN 
    ranked_sales ranked ON isales.total_sold = ranked.ws_quantity
WHERE 
    (isales.total_sold > 5 OR isales.total_returned > 3)
AND 
    (isales.net_sales IS NOT NULL OR isales.total_profit > 100)
ORDER BY 
    isales.total_profit DESC
LIMIT 50;
