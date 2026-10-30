
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
        AND i.i_category = 'Electronics'
    GROUP BY 
        ws.ws_item_sk
),
TopSales AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity,
        r.total_net_paid,
        i.i_item_desc,
        i.i_product_name
    FROM 
        RankedSales r
    JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        r.rank <= 10
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
FinalResults AS (
    SELECT 
        ts.i_item_desc,
        ts.i_product_name,
        ts.total_quantity,
        ts.total_net_paid,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        (ts.total_net_paid - COALESCE(cr.total_return_amount, 0)) AS net_profit_after_returns
    FROM 
        TopSales ts
    LEFT JOIN 
        CustomerReturns cr ON ts.ws_item_sk = cr.sr_item_sk
)
SELECT 
    fr.i_item_desc,
    fr.i_product_name,
    fr.total_quantity,
    fr.total_net_paid,
    fr.total_returns,
    fr.total_return_amount,
    CASE 
        WHEN fr.net_profit_after_returns < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS profit_loss_status
FROM 
    FinalResults fr
ORDER BY 
    fr.total_net_paid DESC;
