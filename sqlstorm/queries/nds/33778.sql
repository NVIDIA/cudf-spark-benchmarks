
WITH  CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    GROUP BY sr_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cr.total_returned, 0) AS total_returned,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        DENSE_RANK() OVER (ORDER BY COALESCE(cr.total_returned, 0) DESC) AS return_rank
    FROM customer c
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
),
MonthlySales AS (
    SELECT 
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_month_seq
),
SalesComparison AS (
    SELECT 
        m1.d_month_seq AS current_month,
        m1.total_sales AS current_sales,
        m2.total_sales AS previous_sales,
        m1.total_sales - COALESCE(m2.total_sales, 0) AS sales_difference
    FROM MonthlySales m1
    LEFT JOIN MonthlySales m2 ON m1.d_month_seq = m2.d_month_seq + 1
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_returned,
    tc.total_return_amount,
    sc.current_month,
    sc.current_sales,
    sc.previous_sales,
    sc.sales_difference
FROM TopCustomers tc
JOIN SalesComparison sc ON tc.return_rank <= 10
ORDER BY sc.sales_difference DESC, tc.total_returned DESC;
