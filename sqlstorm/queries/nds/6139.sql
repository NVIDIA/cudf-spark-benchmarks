
WITH CustomerMetrics AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(COALESCE(ss.ss_net_profit, 0)) AS total_net_profit,
        COUNT(ss.ss_ticket_number) AS total_sales,
        SUM(CASE WHEN ss.ss_sold_date_sk = d.d_date_sk THEN ss.ss_quantity ELSE 0 END) AS sales_today,
        AVG(ss.ss_net_paid) AS avg_net_paid
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
),
TopCustomers AS (
    SELECT
        cm.c_customer_id,
        cm.total_net_profit,
        RANK() OVER (ORDER BY cm.total_net_profit DESC) AS rank
    FROM
        CustomerMetrics cm
)
SELECT
    tc.c_customer_id,
    cm.cd_gender,
    cm.cd_marital_status,
    cm.cd_education_status,
    tc.total_net_profit
FROM
    TopCustomers tc
JOIN
    CustomerMetrics cm ON tc.c_customer_id = cm.c_customer_id
WHERE
    tc.rank <= 10
ORDER BY
    tc.total_net_profit DESC;
