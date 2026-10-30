WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE
        i.i_rec_start_date <= cast('2002-10-01' as date) AND 
        (i.i_rec_end_date >= cast('2002-10-01' as date) OR i.i_rec_end_date IS NULL)
    GROUP BY
        ws.ws_item_sk
),
CustomerReturns AS (
    SELECT
        sr_item_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt) AS total_return_amount
    FROM
        store_returns
    WHERE
        sr_return_quantity > 0
    GROUP BY
        sr_item_sk
),
SalesWithReturns AS (
    SELECT
        r.ws_item_sk,
        r.total_quantity,
        r.total_sales,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        r.total_sales - COALESCE(cr.total_return_amount, 0) AS net_sales
    FROM
        RankedSales r
    LEFT JOIN
        CustomerReturns cr ON r.ws_item_sk = cr.sr_item_sk
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    s.total_quantity,
    s.total_sales,
    s.return_count,
    s.total_return_amount,
    s.net_sales,
    (CASE 
        WHEN s.return_count > 0 THEN 'High Return'
        ELSE 'Low Return'
    END) AS return_category
FROM
    SalesWithReturns s
JOIN
    item i ON s.ws_item_sk = i.i_item_sk
WHERE
    s.net_sales > 0
ORDER BY
    s.net_sales DESC
LIMIT 100;