
WITH RankedSales AS (
    SELECT 
        ss.ss_store_sk,
        ss.ss_item_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_store_sk ORDER BY SUM(ss.ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ss.ss_store_sk, ss.ss_item_sk
),
TopSales AS (
    SELECT 
        r.ss_store_sk,
        r.ss_item_sk,
        r.total_sales,
        COALESCE(ROUND(1.0 * r.total_sales / w.w_warehouse_sq_ft, 2), 0) AS sales_per_sq_ft 
    FROM 
        RankedSales r
    JOIN 
        warehouse w ON r.ss_store_sk = w.w_warehouse_sk
    WHERE 
        r.sales_rank <= 5
),
CustomerReturns AS (
    SELECT 
        sr.sr_item_sk,
        COUNT(sr.sr_return_quantity) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_item_sk
),
FinalSummary AS (
    SELECT 
        t.ss_store_sk,
        t.ss_item_sk,
        t.total_sales,
        t.sales_per_sq_ft,
        COALESCE(c.total_returns, 0) AS total_returns,
        COALESCE(c.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN t.sales_per_sq_ft IS NULL THEN 'No sales data'
            WHEN COALESCE(c.total_returns, 0) > 0 THEN 'Returned'
            ELSE 'Sold'
        END AS sales_status
    FROM 
        TopSales t
    LEFT JOIN 
        CustomerReturns c ON t.ss_item_sk = c.sr_item_sk
)
SELECT 
    f.ss_store_sk,
    f.ss_item_sk,
    f.total_sales,
    f.sales_per_sq_ft,
    f.total_returns,
    f.total_return_amount,
    f.sales_status,
    CASE 
        WHEN f.total_returns = 0 THEN 'No Returns'
        ELSE 'Has Returns'
    END AS return_status,
    LEAD(f.total_sales) OVER (ORDER BY f.ss_store_sk, f.ss_item_sk) AS next_total_sales,
    COUNT(CASE WHEN f.sales_status = 'Returned' THEN 1 END) OVER (PARTITION BY f.ss_store_sk) AS count_returned_items
FROM 
    FinalSummary f
ORDER BY 
    f.ss_store_sk, f.total_sales DESC
LIMIT 100
OFFSET 10;
