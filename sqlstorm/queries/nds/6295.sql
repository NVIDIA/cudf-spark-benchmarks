
WITH SalesData AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discounts,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        COUNT(DISTINCT ws_item_sk) AS distinct_items_sold
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2459950 AND 2459957
    GROUP BY ws_bill_customer_sk
),
CustomerData AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_credit_rating,
        cd_purchase_estimate,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CombinedData AS (
    SELECT
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_discounts, 0) AS total_discounts,
        COALESCE(sd.total_orders, 0) AS total_orders,
        COALESCE(sd.distinct_items_sold, 0) AS distinct_items_sold
    FROM CustomerData cd
    LEFT JOIN SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_education_status,
    c.cd_credit_rating,
    c.total_sales,
    c.total_discounts,
    c.total_orders,
    c.distinct_items_sold
FROM CombinedData c
WHERE c.total_sales > 1000
ORDER BY c.total_sales DESC
LIMIT 10;
