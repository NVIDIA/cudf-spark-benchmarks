
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS sales_rank
    FROM 
        web_sales
), 
returns_summary AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
high_return_items AS (
    SELECT 
        * 
    FROM 
        returns_summary
    WHERE 
        total_returns > (SELECT AVG(total_returns) FROM returns_summary)
)
SELECT 
    ws.ws_item_sk,
    ws.ws_order_number,
    ws.ws_sales_price,
    ws.ws_net_profit,
    COALESCE(hr.total_returns, 0) AS high_return_total,
    COALESCE(hr.total_return_amt, 0) AS return_amount,
    CASE 
        WHEN hr.return_count IS NOT NULL THEN 'High Return'
        ELSE 'Normal Return'
    END AS return_status
FROM 
    web_sales ws
LEFT JOIN 
    high_return_items hr ON ws.ws_item_sk = hr.wr_item_sk
JOIN 
    ranked_sales rs ON ws.ws_item_sk = rs.ws_item_sk AND ws.ws_order_number = rs.ws_order_number
WHERE 
    ws.ws_sales_price > (
        SELECT 
            AVG(ws_sales_price) 
        FROM 
            web_sales
        WHERE 
            ws_sales_price IS NOT NULL
    )
AND 
    (ws.ws_net_profit IS NULL OR ws.ws_net_profit > 100)
ORDER BY 
    ws.ws_item_sk,
    return_status DESC;
