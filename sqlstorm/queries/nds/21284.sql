
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_tax) AS total_return_tax
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk
),
StoreSalesData AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid) AS total_sales,
        SUM(ss_quantity) AS total_items_sold
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        ss_store_sk
),
SalesSummary AS (
    SELECT 
        s.s_store_name,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(sr.total_returns, 0) AS total_returns,
        COALESCE(sr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(sr.total_return_amt, 0) AS total_return_amt,
        COALESCE(sr.total_return_tax, 0) AS total_return_tax,
        CASE 
            WHEN COALESCE(ss.total_sales, 0) > 0 THEN 
                ROUND((COALESCE(sr.total_return_amt, 0) / ss.total_sales) * 100, 2)
            ELSE 0 
        END AS return_rate_percentage
    FROM 
        store AS s
    LEFT JOIN 
        StoreSalesData AS ss ON s.s_store_sk = ss.ss_store_sk
    LEFT JOIN 
        CustomerReturns AS sr ON sr.sr_returned_date_sk = (SELECT MAX(sr_returned_date_sk) FROM CustomerReturns)
)
SELECT 
    s_store_name,
    total_sales,
    total_returns,
    total_return_quantity,
    total_return_amt,
    total_return_tax,
    return_rate_percentage,
    CASE 
        WHEN return_rate_percentage IS NULL THEN 'No returns recorded'
        WHEN return_rate_percentage > 20 THEN 'High Return Rate'
        ELSE 'Normal Return Rate'
    END AS return_rate_description
FROM 
    SalesSummary
WHERE 
    total_sales > 50000 OR total_returns > 10
ORDER BY 
    return_rate_percentage DESC NULLS LAST;
