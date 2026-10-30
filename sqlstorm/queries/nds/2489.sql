
WITH CustomerReturns AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returned,
        SUM(COALESCE(sr_return_amt, 0)) AS total_return_amount
    FROM
        customer AS c
    LEFT JOIN
        store_returns AS sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
),
SalesData AS (
    SELECT
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
CustomerStats AS (
    SELECT
        cr.c_customer_sk,
        cr.c_first_name,
        cr.c_last_name,
        cr.total_returned,
        cr.total_return_amount,
        COALESCE(sd.total_orders, 0) AS total_orders,
        COALESCE(sd.total_sales, 0) AS total_sales,
        CASE
            WHEN cr.total_return_amount > 0 THEN 'Returned Customer'
            ELSE 'Regular Customer'
        END AS customer_type
    FROM
        CustomerReturns AS cr
    LEFT JOIN
        SalesData AS sd ON cr.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_returned,
    cs.total_return_amount,
    cs.total_orders,
    cs.total_sales,
    ROW_NUMBER() OVER (PARTITION BY cs.customer_type ORDER BY cs.total_sales DESC) AS sales_rank
FROM
    CustomerStats AS cs
WHERE
    (cs.total_orders > 1 OR cs.total_returned > 0)
    AND (cs.total_returned IS NOT NULL OR cs.total_sales > 0)
ORDER BY
    cs.total_sales DESC;
