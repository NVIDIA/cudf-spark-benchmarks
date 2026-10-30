
WITH aggregated_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2022
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
),
top_customers AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM
        aggregated_sales
)
SELECT
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_quantity,
    tc.total_spent,
    tc.total_orders,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    cd.cd_purchase_estimate,
    hd.hd_buy_potential,
    hd.hd_vehicle_count
FROM
    top_customers tc
LEFT JOIN
    customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
LEFT JOIN
    household_demographics hd ON tc.c_customer_sk = hd.hd_demo_sk
WHERE
    tc.rank <= 10
ORDER BY
    total_spent DESC;
