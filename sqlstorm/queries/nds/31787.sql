
WITH  sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
    HAVING
        SUM(ws_ext_sales_price) > 0
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        ca.ca_city,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, ca.ca_city, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
final_report AS (
    SELECT
        ci.c_customer_sk,
        ci.ca_city,
        ci.cd_gender,
        ci.cd_marital_status,
        sr.total_sales,
        sr.order_count
    FROM
        customer_info ci
    LEFT JOIN
        sales_summary sr ON ci.c_customer_sk = sr.ws_bill_customer_sk
    WHERE
        ci.total_net_profit > 1000
)
SELECT
    fr.c_customer_sk,
    fr.ca_city,
    fr.cd_gender,
    fr.cd_marital_status,
    COALESCE(fr.total_sales, 0) AS total_sales,
    COALESCE(fr.order_count, 0) AS order_count,
    CASE
        WHEN fr.order_count > 10 THEN 'High'
        WHEN fr.order_count BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS order_category
FROM
    final_report fr
WHERE
    fr.cd_gender IS NOT NULL
ORDER BY
    fr.total_sales DESC;
