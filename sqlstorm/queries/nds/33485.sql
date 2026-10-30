
WITH  sales_summary AS (
    SELECT
        ws_sold_date_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (ORDER BY ws_sold_date_sk) AS row_num
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk
), customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_spent
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, ca.ca_city, ca.ca_state, ca.ca_country
)
SELECT 
    s.ws_sold_date_sk,
    SUM(s.total_orders) AS total_orders,
    AVG(s.total_sales) AS average_sales,
    MAX(s.total_net_paid) AS max_net_paid,
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.ca_city,
    c.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers
FROM
    sales_summary s
LEFT JOIN customer_info c ON s.ws_sold_date_sk = c.total_orders 
WHERE
    (c.cd_gender IS NULL OR c.cd_gender = 'F') AND
    s.total_sales > 1000
GROUP BY
    s.ws_sold_date_sk, c.c_first_name, c.c_last_name, c.cd_gender, c.ca_city, c.ca_state
ORDER BY
    s.ws_sold_date_sk DESC
LIMIT 50
OFFSET 0;
