
WITH CustomerStats AS (
    SELECT
        c.c_customer_sk AS customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_profit) AS average_profit
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate
),
TopCustomers AS (
    SELECT
        customer_sk,
        c_first_name,
        c_last_name,
        total_orders,
        total_spent,
        average_profit,
        RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM
        CustomerStats
)
SELECT
    tc.c_first_name,
    tc.c_last_name,
    tc.total_orders,
    tc.total_spent,
    tc.average_profit,
    ad.ca_city,
    ad.ca_state,
    ad.ca_country
FROM
    TopCustomers tc
JOIN customer_address ad ON tc.customer_sk = ad.ca_address_sk
WHERE
    tc.rank <= 10
ORDER BY
    tc.total_spent DESC;
