
WITH CustomerWithReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(sr.sr_return_quantity) AS total_returned_quantity,
        SUM(sr.sr_return_amt) AS total_returned_amt
    FROM customer c
    JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
), 
HighReturnCustomers AS (
    SELECT 
        cwr.c_customer_sk,
        cwr.c_first_name,
        cwr.c_last_name,
        r.r_reason_desc,
        cwr.total_returned_quantity,
        cwr.total_returned_amt
    FROM CustomerWithReturns cwr
    JOIN store_returns sr ON cwr.c_customer_sk = sr.sr_customer_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE cwr.total_returned_quantity > 5
), 
SalesData AS (
    SELECT 
        ws.ws_ship_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_units_sold
    FROM web_sales ws
    WHERE ws.ws_ship_date_sk BETWEEN '20230101' AND '20231231'
    GROUP BY ws.ws_ship_date_sk
), 
ReturnMetrics AS (
    SELECT 
        hrc.c_customer_sk,
        hrc.c_first_name,
        hrc.c_last_name,
        sd.ws_ship_date_sk,
        sd.total_sales,
        sd.total_units_sold,
        hrc.total_returned_quantity,
        hrc.total_returned_amt
    FROM HighReturnCustomers hrc
    JOIN SalesData sd ON sd.ws_ship_date_sk = '20230101' 
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.total_returned_quantity,
    r.total_returned_amt,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.total_units_sold, 0) AS total_units_sold,
    CASE 
        WHEN COALESCE(s.total_sales, 0) > 0 THEN (r.total_returned_amt / s.total_sales) * 100
        ELSE 0
    END AS return_rate_percentage
FROM ReturnMetrics r
LEFT JOIN SalesData s ON r.ws_ship_date_sk = s.ws_ship_date_sk
ORDER BY return_rate_percentage DESC;
