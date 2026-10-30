
WITH CustomerReturns AS (
    SELECT 
        sr_store_sk,
        sr_returned_date_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS unique_tickets
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk, sr_returned_date_sk
),
SalesData AS (
    SELECT 
        ss_store_sk,
        ss_sold_date_sk,
        SUM(ss_quantity) AS total_sales,
        SUM(ss_sales_price) AS total_sales_value
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk, ss_sold_date_sk
),
DailyStats AS (
    SELECT 
        coalesce(r.sr_store_sk, s.ss_store_sk) AS store_sk,
        d.d_date AS report_date,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(s.total_sales_value, 0) AS total_sales_value,
        COALESCE(r.total_returns, 0) - COALESCE(s.total_sales, 0) AS return_net
    FROM 
        date_dim d
    LEFT JOIN 
        CustomerReturns r ON r.sr_returned_date_sk = d.d_date_sk
    FULL OUTER JOIN 
        SalesData s ON s.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_date BETWEEN '2023-01-01' AND '2023-01-31'
),
RankedStores AS (
    SELECT 
        store_sk, 
        report_date, 
        total_returns, 
        total_sales, 
        total_sales_value,
        return_net,
        RANK() OVER (PARTITION BY store_sk ORDER BY return_net DESC) AS return_rank
    FROM 
        DailyStats
)
SELECT 
    r.store_sk,
    r.report_date,
    r.total_returns,
    r.total_sales,
    r.total_sales_value,
    r.return_net,
    CASE 
        WHEN r.return_rank = 1 THEN 'Highest Return Net'
        WHEN r.return_net < 0 THEN 'Negative Return'
        ELSE 'Normal'
    END AS return_category
FROM 
    RankedStores r
WHERE 
    r.return_net IS NOT NULL
ORDER BY 
    r.report_date, r.return_net DESC;
