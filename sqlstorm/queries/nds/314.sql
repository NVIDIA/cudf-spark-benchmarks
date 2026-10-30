
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS sale_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2452169 AND 2452504 
),
CustomerReturns AS (
    SELECT 
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_return_quantity
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_returned_date_sk, wr.wr_item_sk
),
SalesWithReturns AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_quantity,
        COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
        rs.ws_net_profit
    FROM 
        RankedSales rs
    LEFT JOIN 
        CustomerReturns cr ON rs.ws_item_sk = cr.wr_item_sk
)
SELECT 
    swr.ws_order_number,
    swr.ws_item_sk,
    swr.ws_quantity,
    swr.total_return_quantity,
    CASE 
        WHEN swr.total_return_quantity > 0 THEN 'Returned'
        ELSE 'Sold'
    END AS sale_status,
    AVG(swr.ws_net_profit) OVER (PARTITION BY swr.ws_item_sk) AS avg_net_profit_per_item,
    SUM(swr.ws_quantity) OVER (PARTITION BY swr.ws_item_sk ORDER BY swr.total_return_quantity DESC) AS cumulative_sales
FROM 
    SalesWithReturns swr
WHERE 
    swr.ws_net_profit > 100
GROUP BY 
    swr.ws_order_number,
    swr.ws_item_sk,
    swr.ws_quantity,
    swr.total_return_quantity,
    swr.ws_net_profit
HAVING 
    SUM(swr.ws_quantity) > 10 OR 
    (CASE 
        WHEN swr.total_return_quantity > 0 THEN 'Returned'
        ELSE 'Sold'
    END) = 'Returned'
ORDER BY 
    swr.ws_order_number;
