
WITH  CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt) AS total_returned_amt
    FROM web_returns
    WHERE wr_returned_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY wr_returning_customer_sk
),
ReturnStatistics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(cr.total_returned_amt, 0) AS total_returned_amt,
        DENSE_RANK() OVER (ORDER BY COALESCE(cr.total_returned_quantity, 0) DESC) AS return_rank
    FROM customer c
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
),
SalesStats AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(*) AS total_orders,
        SUM(ws_sales_price) AS total_sales
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY ws_bill_customer_sk
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.total_returned_quantity,
    r.total_returned_amt,
    s.total_orders,
    s.total_sales,
    CASE 
        WHEN s.total_sales > 0 THEN ROUND((r.total_returned_amt / s.total_sales) * 100, 2)
        ELSE NULL 
    END AS return_percentage
FROM ReturnStatistics r
FULL OUTER JOIN SalesStats s ON r.c_customer_sk = s.ws_bill_customer_sk
ORDER BY COALESCE(r.return_rank, 9999), return_percentage DESC
LIMIT 100;
