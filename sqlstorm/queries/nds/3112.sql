
WITH SalesData AS (
    SELECT 
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales,
        RANK() OVER (PARTITION BY ss.ss_sold_date_sk ORDER BY SUM(ss.ss_net_paid_inc_tax) DESC) AS sales_rank
    FROM store_sales ss
    WHERE ss.ss_sales_price > 0
    GROUP BY ss.ss_sold_date_sk, ss.ss_item_sk
),
TopSellingItems AS (
    SELECT 
        sd.ss_sold_date_sk,
        sd.ss_item_sk,
        sd.total_quantity,
        sd.total_sales
    FROM SalesData sd
    WHERE sd.sales_rank <= 10
),
ReturnData AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM store_returns
    GROUP BY sr_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(td.total_quantity, 0) AS total_quantity,
        COALESCE(td.total_sales, 0) AS total_sales,
        COALESCE(rd.total_returns, 0) AS total_returns,
        COALESCE(rd.total_return_value, 0) AS total_return_value
    FROM item i
    LEFT JOIN TopSellingItems td ON i.i_item_sk = td.ss_item_sk
    LEFT JOIN ReturnData rd ON i.i_item_sk = rd.sr_item_sk
)
SELECT 
    id.i_item_sk,
    id.i_item_desc,
    id.total_quantity,
    id.total_sales,
    id.total_returns,
    id.total_return_value,
    (id.total_sales - id.total_return_value) AS net_sales,
    CASE 
        WHEN id.total_returns > 0 THEN (id.total_returns / NULLIF(id.total_quantity, 0)) * 100.0
        ELSE 0
    END AS return_rate
FROM ItemDetails id
WHERE id.total_sales > 1000
ORDER BY net_sales DESC;
