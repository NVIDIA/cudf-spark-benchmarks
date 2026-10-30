
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn,
        SUM(ws_net_profit) OVER (PARTITION BY ws_item_sk) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_return_quantity,
        SUM(wr_return_amt_inc_tax) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
HighReturnItems AS (
    SELECT 
        wr_item_sk
    FROM 
        CustomerReturns
    WHERE 
        total_return_amount > 1000
),
FinalResults AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        rs.ws_sales_price,
        rs.ws_quantity,
        COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        rs.total_profit
    FROM 
        RankedSales rs
    JOIN 
        item i ON i.i_item_sk = rs.ws_item_sk
    LEFT JOIN 
        CustomerReturns cr ON cr.wr_item_sk = rs.ws_item_sk
    WHERE 
        rs.rn = 1
        AND rs.ws_item_sk NOT IN (SELECT wr_item_sk FROM HighReturnItems)
)
SELECT 
    f.i_item_id,
    f.i_item_desc,
    f.ws_sales_price,
    f.ws_quantity,
    f.total_return_quantity,
    f.total_return_amount,
    f.total_profit
FROM 
    FinalResults f
ORDER BY 
    f.total_profit DESC,
    f.ws_sales_price ASC
LIMIT 100;
