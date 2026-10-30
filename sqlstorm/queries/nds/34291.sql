
WITH  sales_summary AS (
    SELECT
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        RANK() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk
),
customer_purchases AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws_ext_sales_price) AS total_web_spent,
        COUNT(ws_order_number) AS total_web_orders
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
top_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cp.total_web_spent,
        cp.total_web_orders,
        ROW_NUMBER() OVER (ORDER BY cp.total_web_spent DESC) AS rank
    FROM
        customer_purchases cp
    JOIN
        customer c ON cp.c_customer_sk = c.c_customer_sk
    WHERE
        cp.total_web_orders > 3
)
SELECT
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    COALESCE(ss.total_sales, 0) AS total_sales,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_web_spent
FROM
    call_center cc
LEFT JOIN
    sales_summary ss ON ss.ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
LEFT JOIN
    top_customers tc ON tc.c_customer_sk = cc.cc_call_center_sk
WHERE
    cc.cc_state = 'CA' AND
    (ss.total_sales IS NOT NULL OR tc.total_web_spent > 1000)
ORDER BY
    total_sales DESC, tc.total_web_spent DESC;
