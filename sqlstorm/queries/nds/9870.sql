
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(d.d_date) AS last_order_date
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM
        customer_demographics cd
)
SELECT
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_web_sales,
    cs.total_orders,
    cs.last_order_date,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    cd.cd_credit_rating,
    cd.cd_dep_count,
    RANK() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
FROM
    CustomerSales cs
JOIN
    CustomerDemographics cd ON cs.c_customer_sk = cd.cd_demo_sk
WHERE
    cs.total_web_sales > 1000
ORDER BY
    sales_rank;
