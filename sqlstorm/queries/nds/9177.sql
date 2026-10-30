
WITH customer_sales AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS total_sales_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY
        c.c_customer_id, cd.cd_gender
),
sales_summary AS (
    SELECT
        cd_gender,
        COUNT(c_customer_id) AS total_customers,
        SUM(total_sales_profit) AS total_profit,
        AVG(avg_order_value) AS avg_order_value_per_customer
    FROM
        customer_sales
    GROUP BY
        cd_gender
)
SELECT
    ss.cd_gender,
    ss.total_customers,
    ss.total_profit,
    ss.avg_order_value_per_customer,
    RANK() OVER (ORDER BY ss.total_profit DESC) AS profit_rank
FROM
    sales_summary ss
WHERE
    ss.total_customers > 100
ORDER BY
    ss.total_profit DESC;
