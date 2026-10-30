
WITH SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE
        i.i_current_price > 0
    GROUP BY
        ws.ws_item_sk
),
TopSellingItems AS (
    SELECT
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.order_count
    FROM
        SalesData sd
    WHERE
        sd.sales_rank <= 10
),
CustomerReturns AS (
    SELECT
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_orders
    FROM
        store_returns sr
    GROUP BY
        sr.sr_item_sk
),
FinalData AS (
    SELECT
        tsi.ws_item_sk,
        tsi.total_quantity,
        tsi.total_sales,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.return_orders, 0) AS return_orders,
        (tsi.total_sales - COALESCE(cr.total_returns * (tsi.total_sales / NULLIF(tsi.total_quantity, 0)), 0)) AS net_sales
    FROM
        TopSellingItems tsi
    LEFT JOIN
        CustomerReturns cr ON tsi.ws_item_sk = cr.sr_item_sk
)
SELECT
    i.i_item_id,
    fd.total_quantity,
    fd.total_sales,
    fd.total_returns,
    fd.return_orders,
    fd.net_sales,
    (fd.net_sales / NULLIF(fd.total_sales, 0)) * 100 AS sales_return_percentage
FROM
    FinalData fd
JOIN
    item i ON fd.ws_item_sk = i.i_item_sk
ORDER BY
    fd.net_sales DESC;
