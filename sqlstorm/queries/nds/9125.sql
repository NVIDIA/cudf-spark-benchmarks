
WITH SalesSummary AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        d.d_year,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        d.d_year
),
CustomerDemographics AS (
    SELECT
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        SUM(total_sales) AS total_sales
    FROM
        SalesSummary
    GROUP BY
        cd_gender,
        cd_marital_status
)
SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count,
    cd.total_sales,
    (cd.total_sales / NULLIF(cd.customer_count, 0)) AS average_sales_per_customer
FROM
    CustomerDemographics cd
ORDER BY
    total_sales DESC;
