
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
), CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CD.cd_credit_rating,
        cd.cd_dep_count,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_purchase
    FROM
        customer_demographics cd
), HighValueCustomers AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM
        CustomerSales cs
    JOIN CustomerDemographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE
        cs.total_sales > 1000 AND cd.rank_by_purchase <= 10
)
SELECT
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_sales,
    COALESCE(cd.cd_gender, 'Unknown') AS gender,
    CASE 
        WHEN cd.cd_marital_status = 'M' THEN 'Married'
        WHEN cd.cd_marital_status = 'S' THEN 'Single'
        ELSE 'Other'
    END AS marital_status,
    cd.cd_education_status
FROM
    HighValueCustomers hvc
LEFT JOIN CustomerDemographics cd ON hvc.c_customer_sk = cd.cd_demo_sk
ORDER BY
    hvc.total_sales DESC
LIMIT 100;
