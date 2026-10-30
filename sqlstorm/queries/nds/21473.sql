WITH  SalesSummary AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS ranking
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
ItemDetails AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        COALESCE(SUM(ws.total_quantity), 0) AS total_quantity,
        COALESCE(SUM(ws.total_revenue), 0) AS total_revenue,
        CASE 
            WHEN SUM(ws.total_quantity) IS NULL THEN 'No Sales'
            WHEN SUM(ws.total_quantity) > 100 THEN 'High Demand'
            ELSE 'Low Demand'
        END AS demand_category
    FROM
        SalesSummary ws
    RIGHT JOIN
        item i ON i.i_item_sk = ws.ws_item_sk
    GROUP BY
        i.i_item_sk, i.i_item_id
),
HighValueReturns AS (
    SELECT
        cr.cr_item_sk,
        COUNT(cr.cr_order_number) AS return_count,
        SUM(cr.cr_return_amount) AS total_return_value
    FROM
        catalog_returns cr
    GROUP BY
        cr.cr_item_sk
    HAVING
        SUM(cr.cr_return_amount) > 1000 
),
FinalReport AS (
    SELECT
        id.i_item_id,
        id.total_quantity,
        id.total_revenue,
        id.demand_category,
        COALESCE(hvr.return_count, 0) AS return_count,
        COALESCE(hvr.total_return_value, 0) AS total_return_value
    FROM
        ItemDetails id
    LEFT JOIN
        HighValueReturns hvr ON id.i_item_sk = hvr.cr_item_sk
    WHERE
        id.total_quantity > 10
)
SELECT
    fr.i_item_id,
    fr.total_quantity,
    fr.total_revenue,
    fr.demand_category,
    fr.return_count,
    fr.total_return_value,
    CASE 
        WHEN fr.total_revenue - fr.total_return_value > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profitability_status,
    CONCAT(fr.i_item_id, ' has ', fr.demand_category, 
           ' sale status with ', fr.return_count, 
           ' returns totaling ', fr.total_return_value) AS item_insights
FROM
    FinalReport fr
ORDER BY
    fr.total_quantity DESC, fr.return_count;