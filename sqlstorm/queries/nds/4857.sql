
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2000000 AND 2000100
),
total_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales_price
    FROM 
        ranked_sales
    WHERE 
        rn <= 5
    GROUP BY 
        ws_item_sk
),
return_data AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(wr.wr_order_number) AS return_count,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    item.i_item_id,
    item.i_item_desc,
    COALESCE(ts.total_sales_price, 0) AS total_sales_price,
    COALESCE(rd.return_count, 0) AS return_count,
    COALESCE(rd.total_return_amt, 0) AS total_return_amt,
    (COALESCE(ts.total_sales_price, 0) - COALESCE(rd.total_return_amt, 0)) AS net_profit
FROM 
    item
LEFT JOIN 
    total_sales ts ON item.i_item_sk = ts.ws_item_sk
LEFT JOIN 
    return_data rd ON item.i_item_sk = rd.wr_item_sk
WHERE 
    (COALESCE(ts.total_sales_price, 0) - COALESCE(rd.total_return_amt, 0)) > 1000
    AND item.i_current_price >= 20
ORDER BY 
    net_profit DESC
LIMIT 10;
