
WITH RankedSales AS (
    SELECT
        ss_store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_ext_sales_price) DESC) AS sales_rank
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY ss_store_sk
),
CustomerReturns AS (
    SELECT
        sr_store_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    WHERE sr_returned_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_month_seq = (SELECT MAX(d_month_seq) FROM date_dim)
    )
    GROUP BY sr_store_sk
),
SalesByRegion AS (
    SELECT
        s.s_store_sk,
        CASE 
            WHEN s.s_state IN ('CA', 'OR', 'WA') THEN 'West'
            WHEN s.s_state IN ('NY', 'NJ', 'PA') THEN 'East'
            WHEN s.s_state IN ('TX', 'OK', 'NM') THEN 'South'
            ELSE 'Other'
        END AS region,
        SUM(ss_ext_sales_price) AS regional_sales,
        COUNT(DISTINCT ss_ticket_number) AS regional_transactions
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY s.s_store_sk, s.s_state
)
SELECT
    s.ss_store_sk AS store_sk,
    s.total_sales,
    s.total_transactions,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    sr.region,
    sr.regional_sales,
    sr.regional_transactions
FROM RankedSales s
LEFT JOIN CustomerReturns r ON s.ss_store_sk = r.sr_store_sk
JOIN SalesByRegion sr ON s.ss_store_sk = sr.s_store_sk
ORDER BY s.total_sales DESC, sr.regional_sales DESC;
