
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid_inc_tax) AS total_store_sales,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales
    FROM
        customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesRanking AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_store_sales,
        cs.total_web_sales,
        RANK() OVER (ORDER BY cs.total_store_sales + cs.total_web_sales DESC) AS sales_rank
    FROM
        CustomerSales cs
),
HighValueCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        COALESCE(cd.cd_purchase_estimate, 0) > 5000 AND
        (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M')
)
SELECT
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    COALESCE(SR.total_store_sales, 0) AS total_store_sales,
    COALESCE(SR.total_web_sales, 0) AS total_web_sales,
    SR.sales_rank
FROM
    HighValueCustomers hvc
LEFT JOIN SalesRanking SR ON hvc.c_customer_sk = SR.c_customer_sk
WHERE
    (SR.total_store_sales + SR.total_web_sales) IS NOT NULL
ORDER BY
    total_store_sales DESC, total_web_sales DESC;
