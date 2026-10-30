
WITH sales_data AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY
        ws_bill_customer_sk
),
customer_data AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT
        cust.c_customer_sk,
        cust.cd_gender,
        cust.cd_marital_status,
        cust.cd_education_status,
        cust.cd_purchase_estimate,
        cust.cd_credit_rating,
        cust.cd_dep_count,
        COALESCE(sales.total_sales, 0) AS total_sales,
        sales.total_orders
    FROM
        customer_data cust
    LEFT JOIN
        sales_data sales ON cust.c_customer_sk = sales.ws_bill_customer_sk
),
ranking AS (
    SELECT
        *,
        DENSE_RANK() OVER (PARTITION BY cd_marital_status ORDER BY total_sales DESC) AS sales_rank
    FROM
        sales_summary
)
SELECT
    r.cd_gender,
    r.cd_marital_status,
    COUNT(*) AS number_of_customers,
    AVG(r.total_sales) AS avg_sales,
    MAX(r.sales_rank) AS max_sales_rank
FROM
    ranking r
WHERE
    r.total_sales > 1000
GROUP BY
    r.cd_gender,
    r.cd_marital_status
ORDER BY
    cd_marital_status, 
    avg_sales DESC;
