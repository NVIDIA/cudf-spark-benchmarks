
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
),

TotalSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        SUM(ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),

CustomerReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt_inc_tax) AS total_returned_amt
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        wr_item_sk
)

SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(TS.total_profit, 0) AS total_profit,
    COALESCE(TS.total_quantity, 0) AS total_quantity,
    COALESCE(TR.total_returned, 0) AS total_returned,
    COALESCE(TR.total_returned_amt, 0) AS total_returned_amt,
    AVG(RS.ws_sales_price) AS avg_sales_price
FROM 
    item i
LEFT JOIN TotalSales TS ON i.i_item_sk = TS.ws_item_sk
LEFT JOIN CustomerReturns TR ON i.i_item_sk = TR.wr_item_sk
LEFT JOIN RankedSales RS ON i.i_item_sk = RS.ws_item_sk AND RS.rank = 1
WHERE 
    (TS.total_profit IS NOT NULL OR TR.total_returned IS NOT NULL)
    AND (i.i_current_price > 20.00 OR i.i_brand LIKE 'BrandA%')
GROUP BY 
    i.i_item_id, 
    i.i_item_desc, 
    TS.total_profit, 
    TS.total_quantity, 
    TR.total_returned, 
    TR.total_returned_amt
ORDER BY 
    total_profit DESC, 
    total_quantity DESC;
