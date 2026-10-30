
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ss.ss_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_sales_price) AS average_sales_price,
        SUM(COALESCE(ss.ss_ext_tax, 0)) AS total_tax
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
),
customer_segments AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.total_transactions,
        CASE 
            WHEN cs.total_sales > 10000 THEN 'High Value'
            WHEN cs.total_sales > 5000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_segment
    FROM customer_sales cs
),
sales_by_segment AS (
    SELECT 
        customer_segment,
        COUNT(*) AS segment_count,
        SUM(total_sales) AS segment_total_sales,
        AVG(total_sales) AS average_sales_per_customer,
        AVG(total_transactions) AS average_transactions_per_customer
    FROM customer_segments
    GROUP BY customer_segment
)
SELECT 
    sbs.customer_segment,
    sbs.segment_count,
    sbs.segment_total_sales,
    sbs.average_sales_per_customer,
    sbs.average_transactions_per_customer,
    wd.d_year
FROM sales_by_segment sbs
JOIN date_dim wd ON wd.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_year = 'Y')
ORDER BY sbs.segment_total_sales DESC;
