
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
SalesData AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
ReturnedSales AS (
    SELECT
        c.c_customer_sk,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_orders, 0) AS total_orders,
        c.c_first_name,
        c.c_last_name
    FROM
        customer c
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
),
RankedReturns AS (
    SELECT
        c.c_customer_sk AS customer_sk,
        total_returns,
        total_sales,
        total_orders,
        CONCAT(c_first_name, ' ', c_last_name) AS customer_name,
        RANK() OVER (ORDER BY total_returns DESC) AS return_rank
    FROM
        ReturnedSales c
)

SELECT
    r.return_rank,
    r.customer_name,
    r.total_returns,
    r.total_sales,
    r.total_orders,
    CASE
        WHEN r.total_sales > 0 THEN ROUND((CAST(r.total_returns AS DECIMAL) / r.total_sales) * 100, 2)
        ELSE 0
    END AS return_percentage
FROM
    RankedReturns r
WHERE
    r.total_returns > 0
ORDER BY
    r.return_rank
LIMIT 10;
