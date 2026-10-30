
WITH RankedStoreSales AS (
    SELECT 
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
HighReturnCustomers AS (
    SELECT 
        sr_customer_sk
    FROM 
        CustomerReturns
    WHERE 
        total_returns > (SELECT AVG(total_returns) FROM CustomerReturns)
),
StoreSalesWithReturns AS (
    SELECT 
        ss.ss_store_sk,
        ss.total_sales,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN cr.total_return_amount IS NULL THEN 'No Returns'
            WHEN cr.total_return_amount > 0 THEN 'Returned'
            ELSE 'No Returns'
        END AS return_status
    FROM 
        RankedStoreSales ss
    LEFT JOIN 
        CustomerReturns cr ON ss.ss_store_sk = cr.sr_customer_sk
),
FinalReport AS (
    SELECT 
        s.s_store_name,
        ss.total_sales,
        ss.total_returns,
        ss.total_return_amount,
        ss.return_status
    FROM 
        StoreSalesWithReturns ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    WHERE 
        ss.total_sales > 1000
)
SELECT 
    f.s_store_name,
    f.total_sales,
    f.total_returns,
    f.total_return_amount,
    f.return_status,
    CASE 
        WHEN f.total_returns > 0 THEN 'High Risk'
        ELSE 'Low Risk'
    END AS customer_risk_level
FROM 
    FinalReport f
ORDER BY 
    f.total_sales DESC
