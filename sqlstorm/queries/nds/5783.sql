WITH sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 2451314 AND 2451380 
    GROUP BY
        ws_bill_customer_sk
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ranked_sales AS (
    SELECT
        cs.ws_bill_customer_sk,
        cs.total_quantity,
        cs.total_sales,
        cs.avg_sales_price,
        cs.order_count,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        ci.cd_credit_rating,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM
        sales_summary cs
    JOIN
        customer_info ci ON cs.ws_bill_customer_sk = ci.c_customer_sk
)
SELECT
    rs.sales_rank,
    rs.c_first_name,
    rs.c_last_name,
    rs.total_quantity,
    rs.total_sales,
    rs.avg_sales_price,
    rs.order_count,
    rs.cd_gender,
    rs.cd_marital_status,
    rs.cd_education_status,
    rs.cd_purchase_estimate,
    rs.cd_credit_rating
FROM
    ranked_sales rs
WHERE
    rs.sales_rank <= 10
ORDER BY
    rs.sales_rank;