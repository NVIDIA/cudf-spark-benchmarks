
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number) AS cumulative_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number DESC) AS rank,
        CASE 
            WHEN ws.ws_net_profit > 0 THEN 'Positive'
            WHEN ws.ws_net_profit < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS profit_status
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
          AND ws.ws_sold_date_sk IN (
              SELECT d_date_sk FROM date_dim
              WHERE d_year = 2023 AND d_moy IN (1, 2)
          )
),
CustomerReturns AS (
    SELECT 
        wr.wr_return_quantity,
        wr.wr_item_sk,
        wr.wr_order_number,
        COALESCE(wr.wr_return_quantity, 0) AS adjusted_return_quantity
    FROM 
        web_returns wr
    LEFT JOIN 
        web_sales ws ON wr.wr_item_sk = ws.ws_item_sk AND wr.wr_order_number = ws.ws_order_number
    WHERE 
        wr.wr_net_loss IS NOT NULL
)
SELECT 
    rs.ws_item_sk,
    COUNT(DISTINCT cr.adjusted_return_quantity) AS total_returns,
    AVG(rs.cumulative_profit) AS avg_cumulative_profit,
    STRING_AGG(DISTINCT rs.profit_status) AS distinct_profit_statuses
FROM 
    RankedSales rs
LEFT JOIN 
    CustomerReturns cr ON rs.ws_item_sk = cr.wr_item_sk
WHERE 
    rs.rank <= 10
GROUP BY 
    rs.ws_item_sk
HAVING 
    SUM(rs.ws_net_profit) IS NOT NULL
ORDER BY 
    avg_cumulative_profit DESC
LIMIT 10 OFFSET 5;
