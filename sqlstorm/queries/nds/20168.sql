
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE
        i.i_current_price IS NOT NULL AND
        i.i_current_price > 0
    GROUP BY
        ws.ws_item_sk
),
FilteredSales AS (
    SELECT
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_sales
    FROM
        RankedSales rs
    WHERE
        rs.sales_rank <= 10
),
CustomerReturns AS (
    SELECT
        cr.cr_item_sk,
        COUNT(cr.cr_order_number) AS return_count,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM
        catalog_returns cr
    GROUP BY
        cr.cr_item_sk
),
SalesAndReturns AS (
    SELECT
        fs.ws_item_sk,
        fs.total_quantity,
        fs.total_sales,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        CASE
            WHEN COALESCE(cr.return_count, 0) > 0 THEN
                'returns present'
            ELSE 
                'no returns'
        END AS return_status
    FROM
        FilteredSales fs
    LEFT JOIN
        CustomerReturns cr ON fs.ws_item_sk = cr.cr_item_sk
)
SELECT
    sa.ws_item_sk,
    sa.total_quantity,
    sa.total_sales,
    sa.return_count,
    sa.total_return_amount,
    sa.return_status,
    ROUND((sa.total_sales - sa.total_return_amount), 2) AS net_sales,
    CASE 
        WHEN sa.return_count > 0 AND sa.total_quantity > 0 THEN 
            ROUND((sa.total_sales - sa.total_return_amount) / NULLIF(sa.total_quantity, 0), 2)
        ELSE 
            NULL 
    END AS avg_sale_per_item
FROM
    SalesAndReturns sa
ORDER BY
    sa.ws_item_sk;
