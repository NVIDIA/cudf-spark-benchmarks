
WITH sales_summary AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS average_profit
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) - 30
                               AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY
        c.c_customer_id, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT
        c.c_customer_id AS customer_id,
        s.total_web_sales,
        s.total_orders,
        s.average_profit,
        RANK() OVER (ORDER BY s.total_web_sales DESC) AS sales_rank
    FROM
        sales_summary s
    JOIN
        customer c ON s.c_customer_id = c.c_customer_id
)
SELECT
    tc.customer_id,
    tc.total_web_sales,
    tc.total_orders,
    tc.average_profit
FROM
    top_customers tc
WHERE
    tc.sales_rank <= 10
ORDER BY
    tc.total_web_sales DESC;
