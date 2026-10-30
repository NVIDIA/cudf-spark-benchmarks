
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
), 
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returns,
        COALESCE(SUM(sr.sr_return_amt), 0) AS total_return_amount
    FROM 
        item i
    LEFT JOIN 
        store_returns sr ON i.i_item_sk = sr.sr_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc, i.i_current_price
),
TopItems AS (
    SELECT 
        id.i_item_sk, 
        id.i_item_desc, 
        id.i_current_price, 
        sd.total_quantity, 
        sd.total_profit, 
        id.total_returns,
        id.total_return_amount,
        RANK() OVER (ORDER BY sd.total_profit DESC) AS profit_rank
    FROM 
        ItemDetails id
    JOIN 
        SalesData sd ON id.i_item_sk = sd.ws_item_sk
)
SELECT 
    ti.i_item_sk, 
    ti.i_item_desc, 
    ti.i_current_price,
    ti.total_quantity,
    ti.total_profit,
    ti.total_returns,
    ti.total_return_amount,
    CASE 
        WHEN ti.total_profit > 0 THEN 'Profitable'
        WHEN ti.total_profit = 0 THEN 'Break-even'
        ELSE 'Loss'
    END AS profit_status
FROM 
    TopItems ti
WHERE 
    ti.profit_rank <= 10 AND
    (ti.total_returns / NULLIF(ti.total_quantity, 0)) > 0.1
ORDER BY 
    ti.total_profit DESC;
