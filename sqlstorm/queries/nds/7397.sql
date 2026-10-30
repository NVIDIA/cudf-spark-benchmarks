
WITH sales_summary AS (
    SELECT
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity_sold,
        SUM(cs_sales_price) AS total_sales_revenue,
        COUNT(DISTINCT cs_order_number) AS total_orders
    FROM
        catalog_sales
    WHERE
        cs_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY
        cs_item_sk
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_purchase_estimate > 1000
),
top_customers AS (
    SELECT
        ws.ws_bill_customer_sk AS c_customer_sk,
        SUM(ss.total_sales_revenue) AS customer_revenue
    FROM
        sales_summary ss
    JOIN
        web_sales ws ON ss.cs_item_sk = ws.ws_item_sk
    JOIN
        customer_info ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    GROUP BY
        ws.ws_bill_customer_sk
    ORDER BY
        customer_revenue DESC
    LIMIT 10
)
SELECT
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    tc.customer_revenue
FROM
    top_customers tc
JOIN
    customer_info ci ON tc.c_customer_sk = ci.c_customer_sk
ORDER BY
    tc.customer_revenue DESC;
