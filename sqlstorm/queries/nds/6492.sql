
WITH RankedSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_sales_price) AS total_spent,
        COUNT(ss.ss_ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ss.ss_sales_price) DESC) AS rank
    FROM
        customer AS c
    JOIN
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE
        ss.ss_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        total_spent,
        total_transactions
    FROM
        RankedSales
    WHERE
        rank <= 10
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        tc.total_spent
    FROM
        customer_demographics AS cd
    JOIN
        TopCustomers AS tc ON tc.c_customer_sk = cd.cd_demo_sk
)
SELECT
    t.c_first_name,
    t.c_last_name,
    t.total_spent,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    cd.cd_credit_rating
FROM
    TopCustomers AS t
JOIN
    CustomerDemographics AS cd ON t.c_customer_sk = cd.cd_demo_sk
ORDER BY
    t.total_spent DESC;
