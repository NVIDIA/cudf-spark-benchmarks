
WITH CustomerData AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_spent
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, hd.hd_income_band_sk, hd.hd_buy_potential
),
TopCustomers AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_spent DESC) AS customer_rank
    FROM
        CustomerData
)
SELECT
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_education_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    tc.total_quantity,
    tc.total_spent
FROM
    TopCustomers tc
JOIN
    income_band ib ON tc.hd_income_band_sk = ib.ib_income_band_sk
WHERE
    tc.customer_rank <= 10
ORDER BY
    tc.total_spent DESC;
