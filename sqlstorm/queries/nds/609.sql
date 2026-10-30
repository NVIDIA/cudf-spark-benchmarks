
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
AggregateReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
TopProducts AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_net_profit,
        ar.total_returns,
        ar.total_return_amount
    FROM 
        RankedSales rs
    INNER JOIN 
        AggregateReturns ar ON rs.ws_item_sk = ar.wr_item_sk
    WHERE 
        rs.rank <= 5
)
SELECT 
    ip.i_item_id,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_profit) AS overall_net_profit,
    COALESCE(AVG(tp.total_returns), 0) AS avg_returns,
    COALESCE(AVG(tp.total_return_amount), 0) AS avg_return_amount
FROM 
    item ip
LEFT JOIN 
    web_sales ws ON ip.i_item_sk = ws.ws_item_sk
LEFT JOIN 
    TopProducts tp ON ip.i_item_sk = tp.ws_item_sk
WHERE 
    ip.i_current_price > 0
GROUP BY 
    ip.i_item_id
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 100
ORDER BY 
    overall_net_profit DESC
LIMIT 10;
