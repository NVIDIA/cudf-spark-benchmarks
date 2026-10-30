
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_net_paid) AS total_net_paid
    FROM 
        RankedSales rs
    WHERE 
        rs.rn <= 3
    GROUP BY 
        rs.ws_item_sk
),
RecentReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned_quantity
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_dow = 1)
    GROUP BY 
        sr_item_sk
),
FinalReport AS (
    SELECT 
        ts.ws_item_sk,
        COALESCE(ts.total_net_paid, 0) AS net_paid_from_sales,
        COALESCE(rr.total_returned_quantity, 0) AS total_returned,
        (COALESCE(ts.total_net_paid, 0) - COALESCE(rr.total_returned_quantity, 0)) AS net_gain_loss
    FROM 
        TopSales ts
    LEFT JOIN 
        RecentReturns rr ON ts.ws_item_sk = rr.sr_item_sk
)
SELECT 
    fr.ws_item_sk,
    fr.net_paid_from_sales,
    fr.total_returned,
    fr.net_gain_loss,
    CASE 
        WHEN fr.net_gain_loss > 0 THEN 'Profitable'
        WHEN fr.net_gain_loss < 0 THEN 'Loss'
        ELSE 'Break-Even'
    END AS profitability_status
FROM 
    FinalReport fr
WHERE 
    fr.net_paid_from_sales > 1000 OR fr.total_returned > 50
ORDER BY 
    fr.net_gain_loss DESC,
    fr.ws_item_sk
LIMIT 10;
