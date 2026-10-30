
WITH  sales_summary AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS rn
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk,
        ws_item_sk
),
customer_info AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT cs_order_number) AS order_count,
        SUM(cs_ext_sales_price) AS total_spent
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status
),
top_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ci.total_spent,
        ROW_NUMBER() OVER (ORDER BY ci.total_spent DESC) AS rank
    FROM
        customer_info ci
    JOIN customer c ON ci.c_customer_sk = c.c_customer_sk
    WHERE
        ci.total_spent IS NOT NULL
)
SELECT
    a.ca_city,
    a.ca_state,
    SUM(ss.total_quantity) AS total_quantity_sold,
    AVG(ss.total_sales) AS avg_sales,
    tc.c_first_name,
    tc.c_last_name,
    tc.rank
FROM
    customer_address a
JOIN customer c ON a.ca_address_sk = c.c_current_addr_sk
JOIN sales_summary ss ON c.c_customer_sk = ss.ws_item_sk
JOIN top_customers tc ON c.c_customer_sk = tc.c_customer_sk
WHERE
    c.c_first_name IS NOT NULL
    AND (c.c_birth_year IS NULL OR c.c_birth_year > 1980)
GROUP BY
    a.ca_city,
    a.ca_state,
    tc.c_first_name,
    tc.c_last_name,
    tc.rank
ORDER BY
    total_quantity_sold DESC
LIMIT 10;
