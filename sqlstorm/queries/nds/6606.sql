
WITH ranked_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_spent
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate
),
customer_performance AS (
    SELECT
        rc.c_customer_sk,
        rc.c_first_name || ' ' || rc.c_last_name AS full_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        rc.cd_purchase_estimate,
        rc.total_quantity,
        rc.total_spent,
        RANK() OVER (ORDER BY rc.total_spent DESC) AS rank_by_spent,
        RANK() OVER (ORDER BY rc.total_quantity DESC) AS rank_by_quantity
    FROM
        ranked_customers rc
)
SELECT
    cp.full_name,
    cp.cd_gender,
    cp.cd_marital_status,
    cp.cd_education_status,
    cp.total_quantity,
    cp.total_spent,
    cp.rank_by_spent,
    cp.rank_by_quantity
FROM
    customer_performance cp
WHERE
    cp.rank_by_spent <= 10 OR cp.rank_by_quantity <= 10
ORDER BY
    cp.rank_by_spent, cp.rank_by_quantity;
