
WITH customer_sales_summary AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY
        c.c_customer_id, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT
        customer_sales_summary.c_customer_id,
        customer_sales_summary.c_first_name,
        customer_sales_summary.c_last_name,
        customer_sales_summary.total_sales,
        customer_sales_summary.order_count
    FROM
        customer_sales_summary
    WHERE
        sales_rank <= 10
),
average_order_value AS (
    SELECT
        c.c_customer_id,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id
)
SELECT
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    a.avg_order_value,
    CASE
        WHEN a.avg_order_value IS NULL THEN 'No Orders'
        WHEN a.avg_order_value < 100 THEN 'Low Value'
        WHEN a.avg_order_value BETWEEN 100 AND 500 THEN 'Medium Value'
        ELSE 'High Value'
    END AS order_value_category
FROM
    top_customers tc
LEFT JOIN
    average_order_value a ON tc.c_customer_id = a.c_customer_id
ORDER BY
    tc.total_sales DESC;
