
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit IS NOT NULL
),
FilteredReturns AS (
    SELECT 
        cr.cr_item_sk,
        COUNT(cr.cr_return_quantity) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_return_quantity > 0
    GROUP BY 
        cr.cr_item_sk
),
ItemProfit AS (
    SELECT 
        i.i_item_sk,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit,
        COALESCE(SUM(fr.total_returns), 0) AS total_returns,
        COALESCE(SUM(fr.total_return_amount), 0) AS total_return_amount
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        FilteredReturns fr ON i.i_item_sk = fr.cr_item_sk
    GROUP BY 
        i.i_item_sk
)
SELECT 
    ip.i_item_sk,
    ip.total_net_profit,
    ip.total_returns,
    ip.total_return_amount,
    CASE 
        WHEN ip.total_returns > 10 THEN 'High Return'
        WHEN ip.total_returns BETWEEN 5 AND 10 THEN 'Moderate Return'
        ELSE 'Low Return'
    END AS return_category,
    CASE 
        WHEN ip.total_net_profit IS NULL THEN 'Profit Not Calculable'
        WHEN ip.total_net_profit <= 0 THEN 'Loss'
        ELSE 'Profit'
    END AS profit_status
FROM 
    ItemProfit ip
WHERE 
    ip.total_net_profit > (SELECT AVG(total_net_profit) FROM ItemProfit)
AND 
    EXISTS (
        SELECT 
            1 
        FROM 
            customer c 
        WHERE 
            c.c_customer_sk IN (
                SELECT DISTINCT sr_customer_sk 
                FROM store_returns 
                WHERE sr_return_quantity IS NOT NULL 
                AND sr_return_quantity > 0
            )
    )
ORDER BY 
    ip.total_net_profit DESC
LIMIT 20;
