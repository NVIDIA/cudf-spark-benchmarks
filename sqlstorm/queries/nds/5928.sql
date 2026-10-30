
WITH  customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
),
top_customers AS (
    SELECT
        *,
        DENSE_RANK() OVER (ORDER BY total_profit DESC) AS rank
    FROM
        customer_sales
)
SELECT
    tc.c_first_name,
    tc.c_last_name,
    tc.total_profit,
    cd.cd_gender,
    cd.cd_marital_status,
    dd.d_year,
    dd.d_month_seq,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    AVG(ws.ws_sales_price) AS avg_item_price
FROM
    top_customers tc
JOIN
    customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
JOIN
    web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
JOIN
    date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
WHERE
    tc.rank <= 10
GROUP BY
    tc.c_first_name,
    tc.c_last_name,
    tc.total_profit,
    cd.cd_gender,
    cd.cd_marital_status,
    dd.d_year,
    dd.d_month_seq
ORDER BY
    total_profit DESC;
