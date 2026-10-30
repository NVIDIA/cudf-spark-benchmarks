
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 1 AND 1000
    GROUP BY
        c.c_customer_sk
),
SalesDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cs.total_sales,
        cs.order_count
    FROM
        customer_demographics cd
    JOIN
        CustomerSales cs ON cd.cd_demo_sk = cs.c_customer_sk
),
SalesSummary AS (
    SELECT
        sd.cd_gender,
        sd.cd_marital_status,
        sd.cd_education_status,
        COUNT(*) AS customer_count,
        SUM(sd.total_sales) AS total_sales_amount,
        AVG(sd.total_sales) AS average_sales,
        SUM(sd.order_count) AS total_orders
    FROM
        SalesDemographics sd
    GROUP BY
        sd.cd_gender, sd.cd_marital_status, sd.cd_education_status
)
SELECT
    s.cd_gender,
    s.cd_marital_status,
    s.cd_education_status,
    s.customer_count,
    s.total_sales_amount,
    s.average_sales,
    s.total_orders,
    CASE
        WHEN s.average_sales > 500 THEN 'High Value'
        WHEN s.average_sales BETWEEN 250 AND 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM
    SalesSummary s
ORDER BY
    s.total_sales_amount DESC;
