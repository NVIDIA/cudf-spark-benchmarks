
WITH  SalesCTE AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid) AS total_sales,
        COUNT(ss_ticket_number) AS sales_count,
        DENSE_RANK() OVER (ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2458489 AND 2458510 
    GROUP BY ss_store_sk
), 
ReturnCTE AS (
    SELECT 
        sr_store_sk,
        SUM(sr_return_amt_inc_tax) AS total_returns
    FROM store_returns
    WHERE sr_returned_date_sk BETWEEN 2458489 AND 2458510
    GROUP BY sr_store_sk
),
FinalSales AS (
    SELECT 
        s.ss_store_sk,
        s.total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        s.sales_count,
        (s.total_sales - COALESCE(r.total_returns, 0)) AS net_sales,
        CASE 
            WHEN s.total_sales = 0 THEN NULL 
            ELSE (COALESCE(r.total_returns, 0) / s.total_sales * 100)
        END AS return_rate 
    FROM SalesCTE s
    LEFT JOIN ReturnCTE r ON s.ss_store_sk = r.sr_store_sk
)
SELECT 
    f.ss_store_sk,
    f.total_sales,
    f.total_returns,
    f.sales_count,
    f.net_sales,
    f.return_rate,
    ROW_NUMBER() OVER (ORDER BY f.net_sales DESC) AS ranking
FROM FinalSales f
WHERE f.net_sales > 5000 
ORDER BY f.net_sales DESC;
