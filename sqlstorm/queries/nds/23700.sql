
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rank_by_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_quantity DESC) AS rank_by_quantity
    FROM
        web_sales
),
SalesSummary AS (
    SELECT
        rs.ws_item_sk,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales,
        COUNT(DISTINCT rs.ws_order_number) AS total_orders
    FROM
        RankedSales rs
    WHERE
        rs.rank_by_price = 1
    OR
        rs.rank_by_quantity = 1
    GROUP BY
        rs.ws_item_sk
),
CustomerReturns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned
    FROM
        store_returns
    GROUP BY
        sr_item_sk
),
FinalReport AS (
    SELECT
        ss.ws_item_sk,
        ss.total_sales,
        ss.total_orders,
        COALESCE(cr.total_returned, 0) AS total_returned,
        CASE
            WHEN ss.total_orders > 0 THEN (total_sales / NULLIF(ss.total_orders, 0))
            ELSE NULL
        END AS avg_sales_per_order
    FROM
        SalesSummary ss
    LEFT JOIN
        CustomerReturns cr ON ss.ws_item_sk = cr.sr_item_sk
)
SELECT
    fr.ws_item_sk,
    fr.total_sales,
    fr.total_orders,
    CASE 
        WHEN fr.total_returned > (fr.total_sales * 0.1) THEN 'High Return'
        WHEN fr.total_returned > (fr.total_sales * 0.05) THEN 'Moderate Return'
        ELSE 'Low Return'
    END AS return_category,
    ROUND(fr.avg_sales_per_order, 2) AS avg_sales_order_value
FROM
    FinalReport fr
WHERE
    fr.total_sales > 1000
ORDER BY
    fr.total_sales DESC
