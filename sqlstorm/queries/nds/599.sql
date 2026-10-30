
WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_web_page_sk) AS unique_pages_viewed
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT
        c.*,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM
        customer_sales c
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    (SELECT AVG(sub.total_sales)
     FROM customer_sales sub) AS average_sales,
    (SELECT COUNT(DISTINCT ws.ws_order_number)
     FROM web_sales ws
     WHERE ws.ws_bill_customer_sk = tc.c_customer_sk) AS total_orders,
    CASE 
        WHEN tc.total_sales IS NULL THEN 'No Sales'
        WHEN tc.total_sales > (SELECT AVG(total_sales) FROM top_customers) THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_performance
FROM
    top_customers tc
WHERE
    tc.sales_rank <= 10
ORDER BY
    tc.total_sales DESC;
