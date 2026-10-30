
WITH SalesData AS (
    SELECT
        ws_item_sk,
        SUM(ws_net_paid) AS total_sales,
        SUM(ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY
        ws_item_sk
),
CustomerInfo AS (
    SELECT
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM
        customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
CategorySales AS (
    SELECT
        i_category,
        SUM(sd.total_sales) AS category_sales,
        SUM(sd.total_quantity) AS category_quantity
    FROM
        SalesData sd
    JOIN item i ON sd.ws_item_sk = i.i_item_sk
    GROUP BY
        i_category
)
SELECT
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    cs.i_category,
    cs.category_sales,
    cs.category_quantity
FROM
    CustomerInfo ci
JOIN CategorySales cs ON ci.c_customer_sk IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022))
ORDER BY
    cs.category_sales DESC, 
    ci.cd_gender;
