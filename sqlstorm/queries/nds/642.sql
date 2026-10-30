
WITH RankedSales AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk,
        ws_item_sk
),
HighPerformanceItems AS (
    SELECT 
        item.i_item_sk,
        item.i_product_name,
        COALESCE(R.total_sales, 0) AS total_sales
    FROM 
        item
    LEFT JOIN RankedSales R ON item.i_item_sk = R.ws_item_sk AND R.sales_rank = 1
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
FinalReport AS (
    SELECT 
        H.i_item_sk,
        H.i_product_name,
        H.total_sales,
        COALESCE(C.return_count, 0) AS return_count,
        COALESCE(C.total_return_amt, 0) AS total_return_amt,
        (H.total_sales - COALESCE(C.total_return_amt, 0)) AS net_sales
    FROM
        HighPerformanceItems H
    LEFT JOIN CustomerReturns C ON H.i_item_sk = C.sr_item_sk
)
SELECT 
    F.i_item_sk,
    F.i_product_name,
    F.total_sales,
    F.return_count,
    F.total_return_amt,
    F.net_sales,
    CASE 
        WHEN F.net_sales > 1000 THEN 'High Performance'
        WHEN F.net_sales BETWEEN 500 AND 1000 THEN 'Medium Performance'
        ELSE 'Low Performance'
    END AS performance_category
FROM 
    FinalReport F
WHERE 
    F.net_sales IS NOT NULL
ORDER BY 
    F.net_sales DESC;
