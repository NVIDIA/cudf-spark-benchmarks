
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
StoreStats AS (
    SELECT 
        ss_store_sk,
        COUNT(DISTINCT ss_customer_sk) AS unique_customers,
        AVG(ss_net_profit) AS avg_net_profit,
        CASE 
            WHEN SUM(ss_quantity) IS NULL THEN 0
            ELSE SUM(ss_quantity)
        END AS total_sales_quantity
    FROM store_sales
    GROUP BY ss_store_sk
),
ReturnDetails AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        CASE 
            WHEN SUM(sr_return_quantity) < 0 THEN NULL
            ELSE SUM(sr_return_quantity)
        END AS adjusted_returns
    FROM store_returns
    GROUP BY sr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(rs.total_quantity, 0) AS total_sold,
    COALESCE(rs.total_net_paid, 0) AS total_net_income,
    COALESCE(ss.unique_customers, 0) AS unique_customers,
    COALESCE(ss.avg_net_profit, 0) AS average_net_profit,
    COALESCE(rd.total_returns, 0) AS total_returns,
    COALESCE(rd.adjusted_returns, 0) AS adjusted_returns,
    COALESCE(ss.total_sales_quantity, 0) AS total_sales_quantity
FROM item i
LEFT JOIN RankedSales rs ON i.i_item_sk = rs.ws_item_sk AND rs.sales_rank = 1
LEFT JOIN StoreStats ss ON ss.ss_store_sk IN (
    SELECT s_store_sk 
    FROM store 
    WHERE s_state = 'CA' AND s_number_employees > 10
)
LEFT JOIN ReturnDetails rd ON rd.sr_item_sk = i.i_item_sk
WHERE (COALESCE(rs.total_net_paid, 0) > 0 OR COALESCE(rd.total_returns, 0) > 0)
  AND i.i_current_price IS NOT NULL
ORDER BY total_net_income DESC, total_sales_quantity ASC
LIMIT 50;
