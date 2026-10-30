
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS SalesRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
),
RecentReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        COUNT(DISTINCT wr.wr_order_number) AS return_orders
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returned_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        wr.wr_item_sk
),
SalesWithReturns AS (
    SELECT 
        r.ws_item_sk,
        r.ws_sales_price,
        r.ws_net_profit,
        COALESCE(rr.total_returned, 0) AS total_returned,
        COALESCE(rr.return_orders, 0) AS return_orders
    FROM 
        RankedSales r
    LEFT JOIN 
        RecentReturns rr ON r.ws_item_sk = rr.wr_item_sk
    WHERE 
        r.SalesRank = 1
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    s.ws_sales_price,
    s.ws_net_profit,
    s.total_returned,
    s.return_orders,
    s.ws_net_profit - (s.total_returned * i.i_current_price) AS adjusted_net_profit
FROM 
    SalesWithReturns s
JOIN 
    item i ON s.ws_item_sk = i.i_item_sk
WHERE 
    (s.ws_net_profit IS NOT NULL AND s.total_returned > 0)
    OR (s.ws_net_profit IS NULL AND s.return_orders > 0)
ORDER BY 
    adjusted_net_profit DESC
LIMIT 10;
