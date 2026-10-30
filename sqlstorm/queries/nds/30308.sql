
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER(PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
), ItemReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
), QualifiedSales AS (
    SELECT 
        s.ws_item_sk,
        SUM(s.ws_net_profit) AS total_net_profit,
        AVG(s.ws_sales_price) AS avg_sales_price,
        COALESCE(ir.total_returned, 0) AS total_returned,
        COALESCE(ir.total_return_amount, 0) AS total_return_amount
    FROM 
        SalesCTE s
    LEFT JOIN 
        ItemReturns ir ON s.ws_item_sk = ir.wr_item_sk
    WHERE 
        s.rn = 1
    GROUP BY 
        s.ws_item_sk, ir.total_returned, ir.total_return_amount
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    qs.total_net_profit,
    qs.avg_sales_price,
    qs.total_returned,
    qs.total_return_amount,
    (QS.total_net_profit - QS.total_return_amount) AS net_profit_after_returns,
    CASE 
        WHEN qs.total_returned > 0 
        THEN 'Item has returns' 
        ELSE 'No returns' 
    END AS return_status
FROM 
    QualifiedSales qs
JOIN 
    item i ON qs.ws_item_sk = i.i_item_sk
WHERE 
    qs.total_net_profit > 1000 OR qs.total_returned > 0
ORDER BY 
    net_profit_after_returns DESC, qs.total_returned ASC;
