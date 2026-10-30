
WITH sales_summary AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_order_number,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM
        catalog_sales cs
    JOIN
        date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
    GROUP BY
        cs.cs_item_sk, cs.cs_order_number
),
customer_summary AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT s.ss_ticket_number) AS total_orders,
        SUM(s.ss_net_paid) AS total_spent
    FROM
        customer c
    LEFT JOIN
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY
        c.c_customer_sk
)
SELECT
    cs.total_orders,
    cs.total_spent,
    ss.total_quantity,
    ss.total_sales,
    ss.total_net_profit,
    (CASE
        WHEN cs.total_spent > 1000 THEN 'High Value'
        WHEN cs.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END) AS customer_value_segment
FROM
    customer_summary cs
JOIN
    sales_summary ss ON cs.total_orders > 0
ORDER BY
    cs.total_spent DESC, ss.total_sales DESC
LIMIT 100;
