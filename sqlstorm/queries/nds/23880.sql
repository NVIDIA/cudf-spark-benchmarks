
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY sr_returned_date_sk DESC) AS rnk
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > (SELECT AVG(sr_return_quantity) FROM store_returns)
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL
    GROUP BY 
        c.c_customer_id
    HAVING 
        SUM(ws.ws_net_profit) > 5000
),
RecentHighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ROW_NUMBER() OVER (ORDER BY hvc.total_net_profit DESC) AS rn
    FROM 
        HighValueCustomers hvc
    JOIN 
        customer c ON hvc.c_customer_id = c.c_customer_id
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
),
RefundAnalysis AS (
    SELECT 
        r.sr_item_sk,
        COUNT(r.sr_item_sk) AS total_returns,
        SUM(r.sr_return_quantity) AS total_returned_quantity,
        COALESCE(SUM(r.sr_net_loss), 0) AS total_net_loss
    FROM 
        store_returns r
    JOIN 
        RankedReturns rr ON rr.sr_item_sk = r.sr_item_sk
    GROUP BY 
        r.sr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ra.total_returns,
    ra.total_returned_quantity,
    ra.total_net_loss,
    rhvc.c_first_name,
    rhvc.c_last_name
FROM 
    item i
JOIN 
    RefundAnalysis ra ON i.i_item_sk = ra.sr_item_sk
JOIN 
    RecentHighValueCustomers rhvc ON ra.total_net_loss > 100
LEFT JOIN 
    customer c ON c.c_customer_id = rhvc.c_customer_id
WHERE 
    ra.total_returns > 1
    AND i.i_current_price IS NOT NULL
    AND EXISTS (
        SELECT 1
        FROM inventory inv 
        WHERE inv.inv_item_sk = i.i_item_sk
        AND inv.inv_quantity_on_hand < 10
    )
ORDER BY 
    ra.total_net_loss DESC, rhvc.rn
LIMIT 10;
