
WITH RankedSales AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 2400 AND 2450
    GROUP BY
        ws_bill_customer_sk
),
PreferredCustomers AS (
    SELECT
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd_credit_rating = 'HIGH' AND cd_marital_status = 'M'
),
TopCustomers AS (
    SELECT
        r.ws_bill_customer_sk,
        r.total_sales,
        pc.cd_gender,
        pc.cd_education_status
    FROM
        RankedSales r
    JOIN PreferredCustomers pc ON r.ws_bill_customer_sk = pc.c_customer_sk
    WHERE
        r.sales_rank = 1
)
SELECT
    tc.ws_bill_customer_sk,
    tc.total_sales,
    COALESCE(tc.cd_gender, 'UNKNOWN') AS gender,
    CASE
        WHEN tc.cd_education_status IS NULL THEN 'NO EDUCATION'
        ELSE tc.cd_education_status
    END AS education_status,
    (SELECT COUNT(*) FROM store_sales ss
     WHERE ss.ss_customer_sk = tc.ws_bill_customer_sk) AS store_sales_count,
    (SELECT COUNT(*) FROM catalog_sales cs
     WHERE cs.cs_bill_customer_sk = tc.ws_bill_customer_sk) AS catalog_sales_count
FROM
    TopCustomers tc
ORDER BY
    total_sales DESC
LIMIT 10;
