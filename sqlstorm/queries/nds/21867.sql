
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sales_price IS NOT NULL
),
SalesSummary AS (
    SELECT 
        ws_order_number,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        COUNT(DISTINCT ws_item_sk) AS unique_items_sold
    FROM RankedSales
    WHERE sales_rank <= 5
    GROUP BY ws_order_number
),
CustomerReturns AS (
    SELECT 
        wr.wr_returning_customer_sk,
        COUNT(*) AS total_returns,
        SUM(wr.wr_return_amt) AS total_returned_amount
    FROM web_returns wr
    WHERE wr.wr_return_quantity > 0
    GROUP BY wr.wr_returning_customer_sk
),
PerformanceMetrics AS (
    SELECT
        c.c_customer_id,
        COALESCE(ss.total_quantity, 0) AS total_quantity_sold,
        COALESCE(ss.total_sales, 0) AS total_sales_value,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_returned_amount, 0) AS total_returned_value,
        CASE 
            WHEN COALESCE(ss.total_quantity, 0) = 0 THEN NULL
            ELSE ROUND(COALESCE(cr.total_returned_amount, 0) / NULLIF(ss.total_sales, 0) * 100, 2)
        END AS return_rate
    FROM customer c
    LEFT JOIN SalesSummary ss ON c.c_customer_sk = ss.ws_order_number
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
    WHERE (c.c_birth_year IS NULL OR c.c_birth_year < 1970) 
       OR (c.c_birth_month IS NULL AND c.c_birth_day IS NOT NULL) 
       OR (c.c_preferred_cust_flag = 'Y' AND c.c_login IS NOT NULL)
)
SELECT 
    COUNT(*) AS customer_count,
    AVG(total_quantity_sold) AS avg_quantity_sold,
    SUM(total_sales_value) AS total_sales,
    MAX(return_rate) AS highest_return_rate
FROM PerformanceMetrics
WHERE total_sales_value > 0
  AND (total_returns > 0 OR return_rate IS NULL);
