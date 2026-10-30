
WITH SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM
        web_sales ws
    GROUP BY
        ws.ws_item_sk
),
TopSellingItems AS (
    SELECT
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales
    FROM
        SalesData sd
    WHERE
        sd.sales_rank <= 5
),
ReturnedItems AS (
    SELECT
        sr_items.sr_item_sk,
        SUM(sr_items.sr_return_quantity) AS total_returns
    FROM
        store_returns sr_items
    GROUP BY
        sr_items.sr_item_sk
),
FinalReport AS (
    SELECT
        ti.ws_item_sk,
        ti.total_quantity,
        ti.total_sales,
        COALESCE(ri.total_returns, 0) AS total_returns,
        (ti.total_sales - COALESCE(ri.total_returns, 0)) AS net_sales
    FROM
        TopSellingItems ti
    LEFT JOIN
        ReturnedItems ri ON ti.ws_item_sk = ri.sr_item_sk
)
SELECT
    f.ws_item_sk,
    f.total_quantity,
    f.total_sales,
    f.total_returns,
    f.net_sales,
    (CASE WHEN f.net_sales > 10000 THEN 'High'
          WHEN f.net_sales BETWEEN 5000 AND 10000 THEN 'Medium'
          ELSE 'Low' END) AS sales_category
FROM
    FinalReport f
ORDER BY
    f.net_sales DESC;
