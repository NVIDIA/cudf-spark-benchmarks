
WITH RankedSales AS (
    SELECT
        ss_store_sk,
        ss_item_sk,
        ss_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY ss_sales_price DESC) AS rnk
    FROM store_sales
    WHERE ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
FilteredStores AS (
    SELECT
        s_store_sk,
        s_store_name,
        SUM(ss_sales_price) AS total_sales
    FROM store s
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE s.s_country IS NOT NULL
    GROUP BY s_store_sk, s_store_name
    HAVING SUM(ss_sales_price) > 10000
),
CustomerReturnSummary AS (
    SELECT
        sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    WHERE sr_return_quantity > 0
    GROUP BY sr_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    fs.s_store_name,
    SUM(CASE WHEN rs.rnk = 1 THEN rs.ss_sales_price ELSE 0 END) AS highest_sale,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    CASE
        WHEN cr.total_return_amount IS NULL THEN 'No Returns'
        WHEN cr.total_return_amount > 1000 THEN 'High Return Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM customer c
LEFT JOIN FilteredStores fs ON c.c_current_addr_sk IS NULL OR fs.s_store_sk = c.c_current_addr_sk
LEFT JOIN RankedSales rs ON c.c_customer_sk = rs.ss_store_sk
LEFT JOIN CustomerReturnSummary cr ON c.c_customer_sk = cr.sr_customer_sk
WHERE c.c_birth_year IS NOT NULL
  AND (c.c_preferred_cust_flag = 'Y' OR fs.s_store_name IS NOT NULL)
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, fs.s_store_name, cr.total_returns, cr.total_return_amount
ORDER BY highest_sale DESC, total_return_amount DESC
LIMIT 50;
