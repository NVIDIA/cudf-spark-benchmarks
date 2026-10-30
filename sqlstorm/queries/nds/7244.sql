
WITH CustomerReturns AS (
    SELECT
        sr_store_sk,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        AVG(sr_return_quantity) AS avg_return_quantity,
        COUNT(DISTINCT sr_customer_sk) AS unique_returning_customers
    FROM store_returns
    WHERE sr_returned_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2023
    )
    GROUP BY sr_store_sk
),
StoreSales AS (
    SELECT
        ss_store_sk,
        SUM(ss_ext_sales_price) AS total_sales_amount,
        COUNT(DISTINCT ss_ticket_number) AS total_sales,
        AVG(ss_quantity) AS avg_sales_quantity
    FROM store_sales
    WHERE ss_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2023
    )
    GROUP BY ss_store_sk
)
SELECT
    c.ca_city,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    COALESCE(ss.total_sales_amount, 0) AS total_sales_amount,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(cr.avg_return_quantity, 0) AS avg_return_quantity,
    COALESCE(ss.avg_sales_quantity, 0) AS avg_sales_quantity,
    (COALESCE(ss.total_sales_amount, 0) - COALESCE(cr.total_return_amount, 0)) AS net_sales
FROM customer_address c
LEFT JOIN CustomerReturns cr ON c.ca_address_sk = cr.sr_store_sk
LEFT JOIN StoreSales ss ON c.ca_address_sk = ss.ss_store_sk
WHERE c.ca_state = 'CA'
ORDER BY net_sales DESC
LIMIT 10;
