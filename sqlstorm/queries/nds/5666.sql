
WITH CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        COUNT(DISTINCT wr_order_number) AS total_orders_returned
    FROM web_returns
    GROUP BY wr_returning_customer_sk
), StoreSales AS (
    SELECT 
        ss_customer_sk,
        SUM(ss_net_paid_inc_tax) AS total_sales_amt_inc_tax,
        COUNT(DISTINCT ss_ticket_number) AS total_orders_sold
    FROM store_sales
    GROUP BY ss_customer_sk
), CombinedStats AS (
    SELECT 
        COALESCE(cu.c_customer_sk, cr.wr_returning_customer_sk) AS customer_sk,
        COALESCE(ct.total_sales_amt_inc_tax, 0) AS total_sales,
        COALESCE(cr.total_return_amt_inc_tax, 0) AS total_returns,
        COALESCE(ct.total_orders_sold, 0) AS total_orders_sold,
        COALESCE(cr.total_orders_returned, 0) AS total_orders_returned
    FROM CustomerReturns cr
    FULL OUTER JOIN StoreSales ct ON cr.wr_returning_customer_sk = ct.ss_customer_sk
    FULL OUTER JOIN customer cu ON cu.c_customer_sk = COALESCE(cr.wr_returning_customer_sk, ct.ss_customer_sk)
)
SELECT 
    customer_sk,
    total_sales,
    total_returns,
    total_orders_sold,
    total_orders_returned,
    CASE 
        WHEN total_sales > 0 THEN ROUND((total_returns / total_sales) * 100, 2) 
        ELSE 0 
    END AS return_rate_percentage
FROM CombinedStats
ORDER BY return_rate_percentage DESC
LIMIT 10;
