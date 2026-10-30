
WITH  sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        DENSE_RANK() OVER (ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales
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
        SUM(ws.ws_sales_price) AS total_web_sales,
        COUNT(ws.ws_order_number) AS web_orders_count
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
customer_address_info AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM
        customer_address ca
    JOIN
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY
        ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.total_orders, 0) AS total_orders,
    cai.ca_city,
    cai.ca_state,
    cai.customer_count,
    ROW_NUMBER() OVER (PARTITION BY ci.cd_gender ORDER BY COALESCE(ss.total_sales, 0) DESC) AS gender_sales_rank
FROM
    customer_info ci
LEFT JOIN
    sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN
    customer_address_info cai ON ci.c_customer_sk = cai.ca_address_sk
WHERE
    ci.total_web_sales IS NOT NULL AND
    (ci.cd_marital_status = 'M' OR ci.cd_marital_status IS NULL)
ORDER BY
    total_sales DESC, ci.c_last_name ASC;
