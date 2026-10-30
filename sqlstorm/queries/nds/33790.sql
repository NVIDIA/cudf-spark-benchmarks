
WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit,
        ws_sold_date_sk
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk, ws_sold_date_sk
),
daily_sales AS (
    SELECT 
        d.d_date,
        s.ws_item_sk,
        s.total_quantity_sold,
        s.total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY s.ws_item_sk ORDER BY d.d_date) AS rnk
    FROM 
        sales_summary s
    JOIN 
        date_dim d ON s.ws_sold_date_sk = d.d_date_sk
),
item_returns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt_inc_tax) AS total_return_amount
    FROM 
        web_returns 
    GROUP BY 
        wr_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(ds.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(ds.total_net_profit, 0) AS total_net_profit,
    COALESCE(ir.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(ir.total_return_amount, 0) AS total_return_amount,
    (COALESCE(ds.total_net_profit, 0) - COALESCE(ir.total_return_amount, 0)) AS net_profit_adjusted
FROM 
    item i
LEFT JOIN 
    daily_sales ds ON i.i_item_sk = ds.ws_item_sk AND ds.rnk = 1
LEFT JOIN 
    item_returns ir ON i.i_item_sk = ir.wr_item_sk
WHERE 
    i.i_current_price > 50
ORDER BY 
    net_profit_adjusted DESC
LIMIT 10;
