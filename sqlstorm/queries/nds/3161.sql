WITH CustomerReturns AS (
    SELECT
        cr_returning_customer_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_quantity) AS total_return_quantity,
        COUNT(DISTINCT cr_order_number) AS total_returns,
        SUM(cr_fee) AS total_fees
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
SalesData AS (
    SELECT
        ws_ship_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity_sold
    FROM web_sales
    GROUP BY ws_ship_customer_sk
),
HighValueCustomers AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        COALESCE(s.total_sales, 0) AS total_sales,
        CASE 
            WHEN COALESCE(s.total_sales, 0) > 1000 THEN 'High Value'
            WHEN COALESCE(s.total_sales, 0) BETWEEN 500 AND 1000 THEN 'Moderate Value'
            ELSE 'Low Value'
        END AS customer_value_category
    FROM customer c
    LEFT JOIN CustomerReturns r ON c.c_customer_sk = r.cr_returning_customer_sk
    LEFT JOIN SalesData s ON c.c_customer_sk = s.ws_ship_customer_sk
    WHERE COALESCE(s.total_sales, 0) > 0 OR COALESCE(r.total_return_amount, 0) > 0
),
RankedCustomers AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY customer_value_category ORDER BY total_sales DESC) AS sales_rank
    FROM HighValueCustomers
    WHERE total_return_amount < 1000 
)
SELECT
    c.customer_value_category,
    c.full_name,
    c.total_sales,
    c.total_return_amount,
    r.sales_rank
FROM RankedCustomers r
JOIN HighValueCustomers c ON r.c_customer_sk = c.c_customer_sk
WHERE r.sales_rank <= 10
ORDER BY c.customer_value_category, r.sales_rank;