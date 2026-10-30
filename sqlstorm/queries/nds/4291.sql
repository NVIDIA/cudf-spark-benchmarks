
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_order_number, ws.ws_sold_date_sk, ws.ws_item_sk
),
TopItems AS (
    SELECT 
        ri.ws_item_sk,
        ri.total_profit
    FROM 
        RankedSales ri
    WHERE 
        ri.profit_rank <= 5
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_item_sk) AS num_returns,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(cr.num_returns, 0) AS num_returns,
    COALESCE(cr.total_return_amt, 0) AS total_return_amt,
    ti.total_profit
FROM 
    customer c
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
JOIN 
    TopItems ti ON c.c_current_cdemo_sk = ti.ws_item_sk
WHERE 
    c.c_birth_year <= 1980
    AND (c.c_preferred_cust_flag = 'Y' OR cr.num_returns > 1)
    AND EXISTS (
        SELECT 1
        FROM inventory inv
        WHERE inv.inv_item_sk = ti.ws_item_sk
        AND inv.inv_quantity_on_hand > 0
    )
ORDER BY 
    total_return_amt DESC
LIMIT 100;
