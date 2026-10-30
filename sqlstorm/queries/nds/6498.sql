
WITH SalesData AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY ws_bill_customer_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesWithCustomer AS (
    SELECT
        sd.ws_bill_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        sd.total_sales,
        sd.total_discount,
        sd.total_orders
    FROM SalesData sd
    JOIN CustomerData cd ON sd.ws_bill_customer_sk = cd.c_customer_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(*) AS customer_count,
    AVG(total_sales) AS avg_sales,
    AVG(total_discount) AS avg_discount,
    AVG(total_orders) AS avg_orders
FROM SalesWithCustomer cd
GROUP BY cd.cd_gender, cd.cd_marital_status
ORDER BY avg_sales DESC
LIMIT 10;
