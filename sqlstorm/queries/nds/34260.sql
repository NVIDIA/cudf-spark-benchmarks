
WITH  SalesCTE AS (
    SELECT
        ss_store_sk,
        SUM(ss_net_paid) AS total_sales,
        COUNT(ss_ticket_number) AS num_transactions,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM
        store_sales
    WHERE
        ss_sold_date_sk BETWEEN 2450501 AND 2451165  
    GROUP BY
        ss_store_sk
),
TopStores AS (
    SELECT
        store.s_store_sk,
        store.s_store_name,
        sales.total_sales,
        sales.num_transactions
    FROM
        store AS store
    JOIN
        SalesCTE AS sales ON store.s_store_sk = sales.ss_store_sk
    WHERE
        sales.sales_rank <= 10  
),
CustomerReturns AS (
    SELECT
        sr_store_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM
        store_returns
    GROUP BY
        sr_store_sk
),
ConsolidatedReports AS (
    SELECT
        ts.s_store_name,
        ts.total_sales,
        ts.num_transactions,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount
    FROM
        TopStores ts
    LEFT JOIN
        CustomerReturns cr ON ts.s_store_sk = cr.sr_store_sk
)
SELECT
    report.s_store_name,
    report.total_sales,
    report.num_transactions,
    report.return_count,
    report.total_return_amount,
    (report.total_sales - report.total_return_amount) AS net_sales,
    (CASE
        WHEN report.num_transactions = 0 THEN 0
        ELSE ROUND((report.return_count::FLOAT / report.num_transactions) * 100, 2)
     END) AS return_percentage
FROM
    ConsolidatedReports report
ORDER BY
    net_sales DESC;
