
WITH CustomerWithReturns AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_store_returns,
        COUNT(DISTINCT wr.wr_order_number) AS total_web_returns,
        SUM(COALESCE(sr.sr_return_amt, 0) + COALESCE(wr.wr_return_amt, 0)) AS total_return_amount
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY c.c_customer_id
),
SalesSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_id
),
FinalReport AS (
    SELECT 
        csr.c_customer_id,
        csr.total_store_returns,
        csr.total_web_returns,
        csr.total_return_amount,
        ss.total_store_sales,
        ss.total_web_sales,
        (COALESCE(ss.total_store_sales, 0) + COALESCE(ss.total_web_sales, 0)) AS total_sales,
        (COALESCE(ss.total_store_sales, 0) + COALESCE(ss.total_web_sales, 0) - COALESCE(csr.total_return_amount, 0)) AS net_sales
    FROM CustomerWithReturns csr
    JOIN SalesSummary ss ON csr.c_customer_id = ss.c_customer_id
)
SELECT 
    c_customer_id AS customer_id,
    total_store_returns,
    total_web_returns,
    total_return_amount,
    total_sales,
    net_sales,
    (CASE 
        WHEN total_sales > 0 THEN (net_sales * 100.0 / total_sales) 
        ELSE 0 
    END) AS return_percentage
FROM FinalReport
ORDER BY net_sales DESC
LIMIT 10;
