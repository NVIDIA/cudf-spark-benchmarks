
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit,
        SUM(ws.ws_net_paid) OVER (PARTITION BY ws.ws_item_sk) AS total_net_paid
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451813 AND 2452200
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        rs.ws_net_profit,
        rs.total_net_paid
    FROM 
        RankedSales rs
    WHERE 
        rs.rank_profit <= 3
),
SalesStatistics AS (
    SELECT 
        ws_item_sk,
        COUNT(*) AS order_count,
        AVG(ws_sales_price) AS avg_sales_price,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        TopSales
    GROUP BY 
        ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr.sr_item_sk,
        COUNT(sr.sr_ticket_number) AS return_count,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_item_sk
)
SELECT 
    ss.ws_item_sk,
    ss.order_count,
    ss.avg_sales_price,
    ss.total_net_profit,
    COALESCE(cr.return_count, 0) AS return_count,
    COALESCE(cr.total_return_amt, 0) AS total_return_amt,
    CASE 
        WHEN cr.total_return_amt IS NULL THEN 'No Returns' 
        WHEN cr.total_return_amt > ss.total_net_profit THEN 'Loss'
        ELSE 'Profitable'
    END AS profitability_status
FROM 
    SalesStatistics ss
LEFT JOIN 
    CustomerReturns cr ON ss.ws_item_sk = cr.sr_item_sk
LEFT JOIN 
    item i ON ss.ws_item_sk = i.i_item_sk
WHERE 
    i.i_current_price > 10.00
    AND ss.order_count > 5
ORDER BY 
    ss.total_net_profit DESC;
