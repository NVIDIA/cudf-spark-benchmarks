
WITH CustomerReturns AS (
    SELECT
        cs_bill_customer_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(cs_order_number) AS order_count,
        AVG(cs_ext_sales_price) AS avg_order_value
    FROM catalog_sales
    WHERE cs_sold_date_sk >= (
        SELECT MAX(d_date_sk) - 30
        FROM date_dim
    )
    GROUP BY cs_bill_customer_sk
),
TopCustomers AS (
    SELECT
        cr.cs_bill_customer_sk,
        cr.total_sales,
        cr.order_count,
        cr.avg_order_value,
        RANK() OVER (ORDER BY cr.total_sales DESC) AS sales_rank
    FROM CustomerReturns cr
    WHERE cr.total_sales > 0
),
ReturnReasons AS (
    SELECT
        wr_returning_customer_sk,
        COUNT(wr_order_number) AS total_returns
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
TopReturnReasons AS (
    SELECT
        wr_returning_customer_sk,
        SUM(total_returns) AS total_return_count
    FROM ReturnReasons
    GROUP BY wr_returning_customer_sk
),
NonReturningCustomers AS (
    SELECT
        c.c_customer_id,
        COALESCE(cr.total_sales, 0) AS total_sales,
        COALESCE(tr.total_return_count, 0) AS total_return_count
    FROM customer c
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.cs_bill_customer_sk
    LEFT JOIN TopReturnReasons tr ON c.c_customer_sk = tr.wr_returning_customer_sk
    WHERE tr.wr_returning_customer_sk IS NULL
)
SELECT 
    nrc.c_customer_id,
    nrc.total_sales,
    nrc.total_return_count,
    CASE 
        WHEN nrc.total_sales > 10000 THEN 'High Value'
        WHEN nrc.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM NonReturningCustomers nrc
WHERE nrc.total_sales > 0
ORDER BY nrc.total_sales DESC;
