
WITH TotalReturns AS (
    SELECT
        sr_item_sk,
        COUNT(*) AS total_return_count,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_tax) AS total_return_tax
    FROM store_returns
    GROUP BY sr_item_sk
),
TopReturningItems AS (
    SELECT
        tr.sr_item_sk,
        i.i_item_desc,
        i.i_current_price,
        tr.total_return_count,
        tr.total_return_amount,
        tr.total_return_tax
    FROM TotalReturns tr
    JOIN item i ON tr.sr_item_sk = i.i_item_sk
    ORDER BY tr.total_return_count DESC
    LIMIT 10
),
SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
CombinedData AS (
    SELECT
        tui.sr_item_sk,
        tui.i_item_desc,
        tui.i_current_price,
        tui.total_return_count,
        tui.total_return_amount,
        tui.total_return_tax,
        COALESCE(sd.total_sales_quantity, 0) AS total_sales_quantity,
        COALESCE(sd.total_sales_amount, 0) AS total_sales_amount
    FROM TopReturningItems tui
    LEFT JOIN SalesData sd ON tui.sr_item_sk = sd.ws_item_sk
)
SELECT
    cd.sr_item_sk,
    cd.i_item_desc,
    cd.i_current_price,
    cd.total_return_count,
    cd.total_return_amount,
    cd.total_return_tax,
    cd.total_sales_quantity,
    cd.total_sales_amount,
    (cd.total_sales_amount - cd.total_return_amount) AS net_sales,
    (cd.total_return_amount / NULLIF(cd.total_sales_amount, 0)) * 100 AS return_percentage
FROM CombinedData cd
ORDER BY return_percentage DESC;
