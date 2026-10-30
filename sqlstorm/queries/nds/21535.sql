
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS unique_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount,
        AVG(sr_return_quantity) AS average_return_quantity
    FROM store_returns
    GROUP BY sr_customer_sk
),
HighReturnCustomers AS (
    SELECT 
        cr.sr_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cr.unique_returns,
        cr.total_returned_amount,
        cr.average_return_quantity
    FROM CustomerReturns cr
    JOIN customer c ON c.c_customer_sk = cr.sr_customer_sk
    WHERE cr.unique_returns > (SELECT AVG(unique_returns) FROM CustomerReturns)
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
)
SELECT
    hrc.sr_customer_sk,
    hrc.c_first_name,
    hrc.c_last_name,
    COALESCE(sd.total_sales_amount, 0) AS total_sales,
    hrc.unique_returns,
    hrc.total_returned_amount,
    hrc.average_return_quantity,
    CASE 
        WHEN hrc.total_returned_amount > 0 THEN 
            ROUND((hrc.total_returned_amount / sd.total_sales_amount) * 100, 2)
        ELSE 0 
    END AS return_percentage,
    CASE 
        WHEN (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_customer_sk = hrc.sr_customer_sk) > 0 
        THEN 'Frequent Returner' 
        ELSE 'Rare Returner' 
    END AS returner_type
FROM HighReturnCustomers hrc
LEFT JOIN SalesData sd ON sd.ws_bill_customer_sk = hrc.sr_customer_sk
ORDER BY return_percentage DESC, hrc.total_returned_amount DESC, hrc.unique_returns DESC
LIMIT 10;

