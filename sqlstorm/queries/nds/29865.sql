
WITH detailed_customers AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        ca.ca_city,
        ca.ca_state
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), sales_summary AS (
    SELECT
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY
        d.d_year
), customer_sales AS (
    SELECT
        dc.c_customer_sk,
        dc.full_name,
        SUM(ws.ws_ext_sales_price) AS customer_sales
    FROM
        detailed_customers dc
    JOIN
        web_sales ws ON dc.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        dc.c_customer_sk, dc.full_name
)
SELECT
    ss.d_year,
    ss.total_sales,
    ss.total_orders,
    ss.unique_customers,
    cs.full_name,
    cs.customer_sales
FROM
    sales_summary ss
LEFT JOIN
    customer_sales cs ON cs.c_customer_sk IS NOT NULL
ORDER BY
    ss.d_year DESC, cs.customer_sales DESC
LIMIT 100;
