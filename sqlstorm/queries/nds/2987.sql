
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_quantity) AS total_quantity,
        SUM(rs.ws_net_profit) AS total_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.rn <= 5
    GROUP BY 
        rs.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
    HAVING 
        SUM(sr_return_quantity) > 0
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ts.total_quantity,
    ts.total_profit,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    i.i_current_price,
    (i.i_current_price * ts.total_quantity) - ts.total_profit + COALESCE(cr.total_return_amount, 0) AS net_profit_after_returns
FROM 
    item i
JOIN 
    TopSales ts ON i.i_item_sk = ts.ws_item_sk
LEFT JOIN 
    CustomerReturns cr ON cr.sr_item_sk = ts.ws_item_sk
WHERE 
    i.i_current_price IS NOT NULL
ORDER BY 
    net_profit_after_returns DESC
LIMIT 10;
