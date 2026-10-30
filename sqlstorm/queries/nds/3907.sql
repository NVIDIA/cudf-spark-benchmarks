WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM
        customer c
    JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE
        ss.ss_sold_date_sk BETWEEN 2451545 AND 2451545 + 60  
    GROUP BY
        c.c_customer_sk
),
return_info AS (
    SELECT
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt) AS total_returned,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count
    FROM
        store_returns sr
    GROUP BY
        sr.sr_customer_sk
),
top_customers AS (
    SELECT
        cs.c_customer_sk,
        cs.total_sales,
        COALESCE(ri.total_returned, 0) AS total_returned,
        cs.total_transactions,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM
        customer_sales cs
    LEFT JOIN
        return_info ri ON cs.c_customer_sk = ri.sr_customer_sk
)
SELECT
    tc.c_customer_sk,
    tc.total_sales,
    tc.total_returned,
    tc.total_transactions,
    ROUND((tc.total_sales - tc.total_returned) / NULLIF(tc.total_sales, 0), 2) AS net_sales_percentage,
    CASE
        WHEN tc.sales_rank <= 10 THEN 'Top'
        ELSE 'Regular'
    END AS customer_segment
FROM
    top_customers tc
WHERE
    tc.total_transactions > 5  
ORDER BY
    tc.sales_rank;