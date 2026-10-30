
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt
    FROM store_returns
    GROUP BY sr_customer_sk
),
RecentSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_web_sales,
        SUM(ws_net_paid_inc_tax) AS total_web_net_paid
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cr.total_returned, 0) AS total_returned,
        COALESCE(rs.total_web_sales, 0) AS total_web_sales,
        CASE 
            WHEN COALESCE(cr.total_returned, 0) > 0 THEN 'High Returner'
            ELSE 'Regular Customer'
        END AS customer_type,
        RANK() OVER (PARTITION BY 
            CASE 
                WHEN COALESCE(cr.total_returned, 0) > 0 THEN 'High Returner' 
                ELSE 'Regular Customer' 
            END 
            ORDER BY COALESCE(rs.total_web_net_paid, 0) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN RecentSales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_returned,
    tc.total_web_sales,
    tc.customer_type,
    tc.sales_rank
FROM TopCustomers tc
WHERE tc.sales_rank <= 10
ORDER BY tc.customer_type, tc.sales_rank;
