
WITH sales_data AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value,
        d.d_year,
        d.d_month_seq
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year, d.d_month_seq
),
ranked_sales AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
    FROM
        sales_data
)
SELECT
    r.c_first_name,
    r.c_last_name,
    r.total_profit,
    r.total_orders,
    r.avg_order_value,
    r.d_year,
    r.d_month_seq
FROM
    ranked_sales r
WHERE
    r.profit_rank <= 10
ORDER BY
    r.d_year ASC,
    r.total_profit DESC;
