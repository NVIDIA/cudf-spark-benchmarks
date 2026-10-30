
WITH  sales_summary AS (
    SELECT 
        ss_sold_date_sk, 
        ss_item_sk, 
        SUM(ss_quantity) AS total_quantity, 
        SUM(ss_net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM store_sales
    GROUP BY ss_sold_date_sk, ss_item_sk
), 
customer_return_summary AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_tax) AS total_return_tax
    FROM store_returns
    GROUP BY sr_item_sk
), 
return_analysis AS (
    SELECT 
        ss.ss_item_sk AS item_sk,
        ss.total_quantity,
        ss.total_sales,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(cr.total_return_tax, 0) AS total_return_tax,
        (CASE WHEN ss.total_sales > 0 
              THEN (COALESCE(cr.total_return_amount, 0) / ss.total_sales) * 100 
              ELSE 0 END) AS return_percentage
    FROM sales_summary ss
    LEFT JOIN customer_return_summary cr ON ss.ss_item_sk = cr.sr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    r.total_quantity,
    r.total_sales,
    r.total_returns,
    r.total_return_amount,
    r.total_return_tax,
    r.return_percentage
FROM return_analysis r
JOIN item i ON r.item_sk = i.i_item_sk
WHERE r.return_percentage > 10
   OR (r.total_sales < 100 AND r.total_returns > 0)
ORDER BY r.return_percentage DESC, r.total_sales DESC
LIMIT 50;
