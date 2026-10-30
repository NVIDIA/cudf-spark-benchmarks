
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_tax) AS total_return_tax,
        SUM(sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM store_returns
    GROUP BY sr_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cr.total_returns,
        cr.total_return_amt,
        cr.total_return_tax,
        cr.total_return_amt_inc_tax,
        cr.total_return_quantity,
        RANK() OVER (ORDER BY cr.total_return_amt DESC) AS rnk
    FROM customer AS c
    JOIN CustomerReturns AS cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE cr.total_return_amt > 100
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CustomerSalesReturns AS (
    SELECT
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(rt.total_returns, 0) AS total_returns,
        COALESCE(rt.total_return_amt, 0) AS total_return_amt,
        COALESCE(sd.total_discount, 0) AS total_discount,
        COALESCE(sd.order_count, 0) AS order_count
    FROM TopCustomers AS tc
    LEFT JOIN SalesData AS sd ON tc.c_customer_sk = sd.ws_bill_customer_sk
    LEFT JOIN CustomerReturns AS rt ON tc.c_customer_sk = rt.sr_customer_sk
)
SELECT 
    c.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_sales,
    cs.total_discount,
    cs.total_returns,
    cs.total_return_amt,
    (cs.total_sales - cs.total_return_amt) AS net_sales,
    (cs.total_returns * 100.0 / NULLIF(cs.order_count, 0)) AS return_rate,
    CASE 
        WHEN cs.total_sales > 0 THEN (cs.total_returns * 100.0 / cs.total_sales) 
        ELSE NULL 
    END AS return_percentage
FROM CustomerSalesReturns cs
JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
WHERE cs.order_count > 0
ORDER BY return_rate DESC, net_sales DESC
LIMIT 100;
