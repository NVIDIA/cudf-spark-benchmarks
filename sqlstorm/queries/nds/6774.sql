
WITH sales_summary AS (
    SELECT
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales_value
    FROM
        catalog_sales cs
    JOIN
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2021 AND 2022
    GROUP BY
        cs.cs_item_sk
),
customer_summary AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        SUM(cs.cs_net_profit) AS total_spent
    FROM
        customer c
    JOIN
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY
        c.c_customer_sk
),
top_items AS (
    SELECT
        ss.cs_item_sk,
        ss.total_quantity,
        ss.total_net_profit,
        ss.total_sales_value,
        RANK() OVER (ORDER BY ss.total_net_profit DESC) AS item_rank
    FROM
        sales_summary ss
),
top_customers AS (
    SELECT
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM
        customer_summary cs
),
final_report AS (
    SELECT
        ti.cs_item_sk,
        ti.total_quantity,
        ti.total_net_profit,
        tc.c_customer_sk,
        tc.total_orders,
        tc.total_spent
    FROM
        top_items ti
    JOIN
        top_customers tc ON tc.customer_rank <= 10 AND ti.item_rank <= 10
)
SELECT
    f.cs_item_sk,
    f.total_quantity,
    f.total_net_profit,
    f.c_customer_sk,
    f.total_orders,
    f.total_spent
FROM
    final_report f
ORDER BY
    f.total_net_profit DESC, f.total_quantity DESC;
