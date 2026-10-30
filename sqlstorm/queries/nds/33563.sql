
WITH  sales_summary AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk, ws_order_number
),
customer_summary AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        c.c_birth_year,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
high_value_customers AS (
    SELECT
        cus.c_customer_sk,
        SUM(sales.total_revenue) AS total_revenue
    FROM
        customer_summary cus
    JOIN
        sales_summary sales ON cus.c_customer_sk = sales.ws_order_number
    WHERE
        cus.gender_rank <= 10 AND sales.rank <= 5
    GROUP BY
        cus.c_customer_sk
)
SELECT
    ca.ca_city,
    COUNT(DISTINCT hv.c_customer_sk) AS high_value_count,
    AVG(hv.total_revenue) AS avg_revenue
FROM
    customer_address ca
LEFT JOIN
    high_value_customers hv ON ca.ca_address_sk = hv.c_customer_sk
WHERE
    ca.ca_state = 'CA'
GROUP BY
    ca.ca_city
ORDER BY
    high_value_count DESC
LIMIT 10;

