
WITH  sales_summary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_ext_sales_price) DESC) AS sales_rank
    FROM store_sales
    GROUP BY ss_store_sk
),
best_stores AS (
    SELECT 
        ss_store_sk,
        total_sales,
        total_transactions
    FROM sales_summary
    WHERE sales_rank <= 5
),
return_data AS (
    SELECT 
        sr_store_sk,
        SUM(sr_return_amt) AS total_returns,
        COUNT(sr_ticket_number) AS total_return_transactions
    FROM store_returns
    GROUP BY sr_store_sk
),
final_report AS (
    SELECT 
        b.ss_store_sk,
        b.total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        b.total_transactions,
        (b.total_sales - COALESCE(r.total_returns, 0)) AS net_sales
    FROM best_stores b
    LEFT JOIN return_data r ON b.ss_store_sk = r.sr_store_sk
)

SELECT 
    s.s_store_id,
    s.s_store_name,
    f.total_sales,
    f.total_returns,
    f.total_transactions,
    f.net_sales,
    (f.net_sales / NULLIF(f.total_transactions, 0)) AS avg_sales_per_transaction,
    CASE 
        WHEN f.net_sales > 10000 THEN 'High Performer'
        WHEN f.net_sales BETWEEN 5000 AND 10000 THEN 'Medium Performer'
        ELSE 'Low Performer' 
    END AS performance_category
FROM final_report f
JOIN store s ON f.ss_store_sk = s.s_store_sk
ORDER BY f.net_sales DESC;
