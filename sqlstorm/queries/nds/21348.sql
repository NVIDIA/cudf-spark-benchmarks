
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ship_mode_sk,
        RANK() OVER (PARTITION BY ws.ws_item_sk, ws.ws_ship_mode_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL
        AND i.i_current_price > 0
        AND ws.ws_ship_date_sk IS NOT NULL
),
SelectedSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_quantity,
        CAST(rs.profit_rank AS CHAR(2)) AS profit_rank_str,
        'Sale ID ' || rs.ws_order_number || ' with quantity ' || rs.ws_quantity AS sale_details
    FROM 
        RankedSales rs
    WHERE 
        rs.profit_rank = 1
),
TotalReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
FinalResults AS (
    SELECT 
        ss.ws_item_sk,
        ss.sale_details,
        COALESCE(tr.total_returned, 0) AS total_returned
    FROM 
        SelectedSales ss
    LEFT JOIN 
        TotalReturns tr ON ss.ws_item_sk = tr.cr_item_sk
)
SELECT 
    fr.ws_item_sk,
    fr.sale_details,
    fr.total_returned,
    CASE 
        WHEN fr.total_returned > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status,
    CASE 
        WHEN fr.total_returned > 0 THEN fr.total_returned * (SELECT AVG(sr.ws_net_paid) FROM web_sales sr WHERE sr.ws_item_sk = fr.ws_item_sk)
        ELSE NULL
    END AS estimated_loss,
    CONCAT('Item: ', fr.ws_item_sk, ' - ', fr.sale_details) AS item_summary
FROM 
    FinalResults fr
WHERE 
    fr.total_returned IS NOT NULL
      OR fr.total_returned IS NULL
ORDER BY 
    fr.total_returned DESC
LIMIT 100;
