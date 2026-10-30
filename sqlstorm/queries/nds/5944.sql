
WITH sales_data AS (
    SELECT
        w.w_warehouse_name,
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM
        web_sales ws
    JOIN
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year >= 2022
    GROUP BY
        w.w_warehouse_name, d.d_year, d.d_month_seq
),
customer_sales AS (
    SELECT
        c.c_customer_id,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id
),
top_customers AS (
    SELECT
        cs.c_customer_id,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM
        customer_sales cs
)
SELECT
    sd.w_warehouse_name,
    sd.d_year,
    sd.d_month_seq,
    sd.total_quantity,
    sd.total_sales,
    sd.avg_net_profit,
    tc.c_customer_id,
    tc.total_spent,
    tc.customer_rank
FROM
    sales_data sd
JOIN
    top_customers tc ON sd.total_sales > 10000
ORDER BY
    sd.d_year, sd.d_month_seq, tc.customer_rank
LIMIT 10;
