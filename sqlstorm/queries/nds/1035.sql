
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_returned_date_sk) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM store_returns
    GROUP BY sr_customer_sk
),
TopCustomers AS (
    SELECT 
        cr.sr_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cr.total_returns,
        cr.total_return_amount,
        ROW_NUMBER() OVER (ORDER BY cr.total_return_amount DESC) AS rank
    FROM CustomerReturns cr
    JOIN customer c ON cr.sr_customer_sk = c.c_customer_sk
    WHERE cr.total_return_amount > 0
),
SalesSummary AS (
    SELECT 
        w.ws_bill_customer_sk,
        SUM(w.ws_ext_sales_price) AS total_sales,
        COUNT(w.ws_order_number) AS total_orders,
        AVG(w.ws_net_profit) AS average_net_profit
    FROM web_sales w
    GROUP BY w.ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        tc.sr_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.total_orders, 0) AS total_orders,
        tc.total_returns,
        tc.total_return_amount,
        RANK() OVER (ORDER BY COALESCE(ss.total_sales, 0) DESC) AS sales_rank
    FROM TopCustomers tc
    LEFT JOIN SalesSummary ss ON tc.sr_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    f.sr_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.total_sales,
    f.total_orders,
    f.total_returns,
    f.total_return_amount,
    f.sales_rank
FROM FinalReport f
WHERE f.sales_rank <= 10
ORDER BY f.total_sales DESC, f.total_returns DESC;
