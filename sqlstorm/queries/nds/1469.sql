
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        COUNT(sr_returned_date_sk) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
SalesData AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM
        web_sales
    WHERE
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws_bill_customer_sk
),
AggregatedData AS (
    SELECT
        c.c_customer_id,
        COALESCE(cr.total_returns, 0) AS customer_returns,
        COALESCE(sd.total_sales, 0) AS total_sales,
        sd.total_orders
    FROM
        customer c
    LEFT JOIN
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN
        SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT
    a.c_customer_id,
    a.customer_returns,
    a.total_sales,
    CASE
        WHEN a.customer_returns > 0 THEN 'Returner'
        ELSE 'Non-Returner'
    END AS return_status,
    RANK() OVER (ORDER BY a.total_sales DESC) AS sales_rank,
    CASE 
        WHEN a.total_sales > 1000 THEN 'High Value'
        WHEN a.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM
    AggregatedData a
WHERE
    a.customer_returns > 0 OR a.total_sales > 0
ORDER BY
    return_status, sales_rank;
