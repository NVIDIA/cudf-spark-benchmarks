WITH SalesData AS (
    SELECT
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_sales_quantity,
        SUM(cs.cs_ext_sales_price) AS total_sales_value,
        COUNT(DISTINCT cs.cs_order_number) AS total_transactions
    FROM
        catalog_sales cs
    WHERE
        cs.cs_sold_date_sk BETWEEN 2459939 AND 2460563 
    GROUP BY
        cs.cs_item_sk
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate
),
TopItems AS (
    SELECT
        sd.cs_item_sk,
        sd.total_sales_quantity,
        sd.total_sales_value,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM
        SalesData sd
    JOIN
        CustomerDemographics cd ON sd.cs_item_sk = cd.cd_demo_sk
    ORDER BY
        sd.total_sales_value DESC
    LIMIT 10
)
SELECT
    ti.cs_item_sk,
    ti.total_sales_quantity,
    ti.total_sales_value,
    ti.cd_gender,
    ti.cd_marital_status,
    ti.cd_education_status
FROM
    TopItems ti;