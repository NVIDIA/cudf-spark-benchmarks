
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerReturns AS (
    SELECT
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_returned
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY sr.sr_customer_sk
),
CombinedData AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        COALESCE(cs.total_web_sales, 0) AS total_web_sales,
        COALESCE(cr.total_returned, 0) AS total_returned,
        CASE
            WHEN COALESCE(cs.total_web_sales, 0) > COALESCE(cr.total_returned, 0) THEN 'Net Positive'
            WHEN COALESCE(cs.total_web_sales, 0) < COALESCE(cr.total_returned, 0) THEN 'Net Negative'
            ELSE 'Break Even'
        END AS net_status
    FROM CustomerSales cs
    FULL OUTER JOIN CustomerReturns cr ON cs.c_customer_sk = cr.sr_customer_sk
)
SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.total_web_sales,
    c.total_returned,
    c.net_status,
    RANK() OVER (ORDER BY c.total_web_sales - c.total_returned DESC) AS sales_rank
FROM CombinedData c
WHERE c.total_web_sales > 500
ORDER BY c.total_web_sales - c.total_returned DESC
LIMIT 10;
