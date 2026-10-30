
WITH  sales_summary AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
top_sales AS (
    SELECT
        ws_item_sk,
        total_quantity,
        total_revenue
    FROM
        sales_summary
    WHERE
        rank <= 10
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        CASE 
            WHEN cd.cd_dep_count IS NULL THEN 'N/A'
            ELSE CAST(cd.cd_dep_count AS STRING)
        END AS dependent_count
    FROM
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    COALESCE(ss.total_quantity, 0) AS quantity_sold,
    COALESCE(ss.total_revenue, 0.00) AS revenue_generated,
    ci.dependent_count,
    CASE
        WHEN ci.cd_credit_rating = 'High' THEN 'Premium'
        WHEN ci.cd_credit_rating = 'Medium' THEN 'Standard'
        ELSE 'Low'
    END AS credit_category
FROM
    customer_info ci
LEFT JOIN (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_revenue
    FROM
        web_sales
    WHERE
        ws_item_sk IN (SELECT ws_item_sk FROM top_sales)
    GROUP BY
        ws_bill_customer_sk
) ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
ORDER BY
    revenue_generated DESC NULLS LAST;
