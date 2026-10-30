
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr_return_tax) AS total_tax
    FROM store_returns
    GROUP BY sr_customer_sk
),
TopCustomers AS (
    SELECT 
        cr.sr_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cr.total_return_quantity,
        cr.total_return_amount
    FROM CustomerReturns cr
    JOIN customer c ON cr.sr_customer_sk = c.c_customer_sk
    WHERE cr.total_return_quantity > (
        SELECT AVG(total_return_quantity) 
        FROM CustomerReturns
    )
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_ext_sales_price) AS total_sales_amount
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        tc.sr_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        COALESCE(sd.total_sales_quantity, 0) AS total_sales_quantity,
        COALESCE(sd.total_sales_amount, 0) AS total_sales_amount,
        tc.total_return_quantity,
        tc.total_return_amount
    FROM TopCustomers tc
    LEFT JOIN SalesData sd ON tc.sr_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    fr.c_first_name,
    fr.c_last_name,
    fr.total_sales_quantity,
    fr.total_sales_amount,
    fr.total_return_quantity,
    fr.total_return_amount,
    (fr.total_sales_amount - fr.total_return_amount) AS net_sales_amount
FROM FinalReport fr
WHERE fr.total_sales_quantity > 10
ORDER BY net_sales_amount DESC;
