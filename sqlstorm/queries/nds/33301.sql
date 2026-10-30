
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        ws_item_sk
),
CustomerReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_net_loss) AS total_return_loss
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk IN (
            SELECT 
                d_date_sk 
            FROM 
                date_dim 
            WHERE 
                d_year = 2023 AND d_month_seq = 12
        )
    GROUP BY 
        wr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(S.total_net_profit, 0) AS total_net_profit,
    COALESCE(R.total_return_loss, 0) AS total_return_loss,
    (COALESCE(S.total_net_profit, 0) - COALESCE(R.total_return_loss, 0)) AS net_value
FROM 
    item i
LEFT JOIN 
    SalesCTE S ON i.i_item_sk = S.ws_item_sk
LEFT JOIN 
    CustomerReturns R ON i.i_item_sk = R.wr_item_sk
WHERE 
    i.i_current_price > 0
ORDER BY 
    net_value DESC
LIMIT 10;

