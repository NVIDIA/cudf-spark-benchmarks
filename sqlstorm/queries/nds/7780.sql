
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk
),
TopCustomers AS (
    SELECT
        cs.c_customer_sk,
        cs.total_sales,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM
        CustomerSales cs
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_dep_count,
        cd.cd_credit_rating
    FROM
        customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
),
SalesSummary AS (
    SELECT
        tc.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        tc.total_sales,
        tc.order_count
    FROM
        TopCustomers tc
    JOIN CustomerDemographics cd ON tc.c_customer_sk = cd.cd_demo_sk
    WHERE
        tc.sales_rank <= 10
)
SELECT
    s.cd_gender,
    s.cd_marital_status,
    s.cd_education_status,
    COUNT(*) AS number_of_top_customers,
    AVG(s.total_sales) AS avg_sales,
    SUM(s.order_count) AS total_orders
FROM
    SalesSummary s
GROUP BY
    s.cd_gender,
    s.cd_marital_status,
    s.cd_education_status
ORDER BY
    number_of_top_customers DESC;
