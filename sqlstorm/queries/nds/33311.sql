
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        MIN(ws_sold_date_sk) AS first_sale_date,
        MAX(ws_sold_date_sk) AS last_sale_date,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 1)
    GROUP BY 
        ws_item_sk
),
TopSales AS (
    SELECT 
        s.ws_item_sk,
        i.i_item_id,
        i.i_product_name,
        s.total_quantity, 
        s.total_net_profit 
    FROM 
        SalesCTE s
    JOIN 
        item i ON s.ws_item_sk = i.i_item_sk
    WHERE 
        s.rank <= 10
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns 
    GROUP BY 
        sr_item_sk
),
FinalResults AS (
    SELECT 
        ts.ws_item_sk,
        ts.i_item_id,
        ts.i_product_name,
        ts.total_quantity,
        ts.total_net_profit,
        COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        (ts.total_net_profit - COALESCE(cr.total_return_amt, 0)) AS net_profit_after_returns,
        CASE 
            WHEN COALESCE(cr.total_return_quantity, 0) > 0 THEN 'Has Returns'
            ELSE 'No Returns'
        END AS return_status
    FROM 
        TopSales ts
    LEFT JOIN 
        CustomerReturns cr ON ts.ws_item_sk = cr.sr_item_sk
)
SELECT 
    f.ws_item_sk,
    f.i_item_id,
    f.i_product_name,
    f.total_quantity,
    f.total_net_profit,
    f.total_return_quantity,
    f.total_return_amt,
    f.net_profit_after_returns,
    f.return_status
FROM 
    FinalResults f
ORDER BY 
    f.net_profit_after_returns DESC
LIMIT 10;
