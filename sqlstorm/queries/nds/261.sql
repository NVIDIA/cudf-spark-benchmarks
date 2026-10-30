
WITH RankedReturns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        COUNT(sr_ticket_number) AS return_count,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_quantity) DESC) AS rn
    FROM
        store_returns
    GROUP BY
        sr_item_sk
),
PopularItems AS (
    SELECT
        i_item_sk,
        i_item_id,
        i_item_desc,
        i_current_price,
        COALESCE(ir.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(ir.return_count, 0) AS return_count,
        CASE 
            WHEN COALESCE(ir.total_returned_quantity, 0) > 10 THEN 'High'
            WHEN COALESCE(ir.total_returned_quantity, 0) BETWEEN 5 AND 10 THEN 'Medium'
            ELSE 'Low'
        END AS return_category
    FROM
        item i
    LEFT JOIN RankedReturns ir ON i.i_item_sk = ir.sr_item_sk AND ir.rn = 1
),
SalesStats AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS sales_count
    FROM
        web_sales ws
    GROUP BY
        ws.ws_item_sk
)
SELECT
    pi.i_item_id,
    pi.i_item_desc,
    pi.i_current_price,
    pi.return_category,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.sales_count, 0) AS sales_count,
    (COALESCE(ss.total_sales, 0) - COALESCE(ir.total_returned_quantity, 0) * pi.i_current_price) AS net_profit_after_returns
FROM
    PopularItems pi
LEFT JOIN SalesStats ss ON pi.i_item_sk = ss.ws_item_sk
LEFT JOIN RankedReturns ir ON pi.i_item_sk = ir.sr_item_sk
WHERE
    pi.return_category = 'High' OR
    (pi.return_category = 'Medium' AND ss.total_sales > 100)
ORDER BY
    net_profit_after_returns DESC
LIMIT 10;
