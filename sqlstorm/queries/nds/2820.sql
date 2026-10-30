
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER(PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws 
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
FilteredReturns AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_return
    FROM 
        store_returns sr 
    WHERE 
        sr.sr_returned_date_sk IS NOT NULL
    GROUP BY 
        sr.sr_customer_sk
)
SELECT 
    c.c_customer_id,
    cs.total_profit,
    cs.order_count,
    COALESCE(fr.total_return, 0) AS total_return,
    (cs.total_profit - COALESCE(fr.total_return, 0)) AS net_profit_loss,
    CASE 
        WHEN cs.total_profit - COALESCE(fr.total_return, 0) > 0 THEN 'Profitable'
        WHEN cs.total_profit - COALESCE(fr.total_return, 0) < 0 THEN 'Loss'
        ELSE 'Break Even'
    END AS profit_status
FROM 
    CustomerSales cs
LEFT JOIN 
    FilteredReturns fr ON cs.c_customer_sk = fr.sr_customer_sk
JOIN 
    customer c ON c.c_customer_sk = cs.c_customer_sk
WHERE 
    cs.order_count > 5
ORDER BY 
    net_profit_loss DESC
LIMIT 100;
