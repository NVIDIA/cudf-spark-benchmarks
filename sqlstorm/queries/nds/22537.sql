WITH RankedSales AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_paid) DESC) AS rank
    FROM store_sales
    WHERE ss_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim) 
    GROUP BY ss_store_sk, ss_item_sk
),
RecentReturns AS (
    SELECT 
        sr_store_sk, 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    WHERE sr_returned_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim) 
    GROUP BY sr_store_sk, sr_item_sk
),
SalesAndReturns AS (
    SELECT 
        rs.ss_store_sk,
        rs.ss_item_sk,
        COALESCE(rs.total_quantity, 0) AS total_quantity,
        COALESCE(rs.total_sales, 0) AS total_sales,
        COALESCE(rr.total_returns, 0) AS total_returns,
        COALESCE(rr.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN COALESCE(rs.total_sales, 0) = 0 THEN NULL
            ELSE (COALESCE(rr.total_return_amount, 0) / COALESCE(rs.total_sales, 0)) * 100
        END AS return_percentage
    FROM RankedSales rs
    FULL OUTER JOIN RecentReturns rr ON rs.ss_store_sk = rr.sr_store_sk AND rs.ss_item_sk = rr.sr_item_sk
),
ItemDetails AS (
    SELECT 
        s.s_store_id,
        i.i_item_id,
        i.i_item_desc,
        sar.total_quantity,
        sar.total_sales,
        sar.total_returns,
        sar.total_return_amount,
        sar.return_percentage
    FROM SalesAndReturns sar
    JOIN store s ON sar.ss_store_sk = s.s_store_sk
    JOIN item i ON sar.ss_item_sk = i.i_item_sk
)
SELECT 
    id.s_store_id,
    id.i_item_id,
    id.i_item_desc,
    id.total_quantity,
    id.total_sales,
    id.total_returns,
    id.total_return_amount,
    id.return_percentage,
    CASE 
        WHEN id.return_percentage IS NOT NULL AND id.return_percentage > 50 THEN 'High Returns'
        WHEN id.return_percentage IS NULL THEN 'No Sales'
        ELSE 'Normal Returns'
    END AS return_category
FROM ItemDetails id
WHERE id.return_percentage IS NULL OR id.return_percentage > 20
ORDER BY id.total_sales DESC, id.return_percentage ASC
LIMIT 100;