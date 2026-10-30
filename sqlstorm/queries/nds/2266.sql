
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = '2002-10-01')
),
TotalReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_tax) AS total_return_tax
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
StoreProfit AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_net_profit) AS total_profit
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    WHERE 
        s.s_state = 'CA'
    GROUP BY 
        s.s_store_sk
)
SELECT 
    r.ws_order_number,
    r.ws_item_sk,
    r.ws_sales_price,
    r.ws_quantity,
    COALESCE(tr.total_returned, 0) AS total_returned,
    COALESCE(tr.total_return_amount, 0) AS total_return_amount,
    COALESCE(tr.total_return_tax, 0) AS total_return_tax,
    sp.total_profit,
    CASE 
        WHEN sp.total_profit IS NULL THEN 'No Profit'
        ELSE 'Profitable'
    END AS profit_status
FROM 
    RankedSales r
LEFT JOIN 
    TotalReturns tr ON r.ws_item_sk = tr.cr_item_sk
LEFT JOIN 
    StoreProfit sp ON r.ws_item_sk IN (SELECT cs.cs_item_sk FROM catalog_sales cs WHERE cs.cs_order_number = r.ws_order_number)
WHERE 
    r.rn = 1
ORDER BY 
    r.ws_order_number, total_returned DESC;
