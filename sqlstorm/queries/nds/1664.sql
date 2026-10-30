
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
TopSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        i.i_item_desc,
        i.i_current_price
    FROM SalesData sd
    JOIN item i ON sd.ws_item_sk = i.i_item_sk
    WHERE sd.sales_rank <= 10
),
ReturnStats AS (
    SELECT 
        cr_item_sk,
        COUNT(DISTINCT cr_order_number) AS total_returns,
        SUM(cr_return_amount) AS total_return_amount
    FROM catalog_returns
    GROUP BY cr_item_sk
)
SELECT 
    ts.ws_item_sk,
    ts.i_item_desc,
    ts.total_quantity,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN ts.total_sales > 0 THEN 
            ROUND((COALESCE(rs.total_return_amount, 0) / ts.total_sales) * 100, 2)
        ELSE 0
    END AS return_percentage
FROM TopSales ts
LEFT JOIN ReturnStats rs ON ts.ws_item_sk = rs.cr_item_sk
ORDER BY return_percentage DESC;
