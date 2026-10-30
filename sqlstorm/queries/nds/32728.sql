
WITH  sales_summary AS (
    SELECT
        ws_ship_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales
    FROM
        web_sales
    WHERE
        ws_ship_date_sk BETWEEN 2400 AND 2500
    GROUP BY
        ws_ship_date_sk, ws_item_sk
    UNION ALL
    SELECT
        cs_ship_date_sk,
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid_inc_tax) AS total_sales
    FROM
        catalog_sales
    WHERE
        cs_ship_date_sk BETWEEN 2400 AND 2500
    GROUP BY
        cs_ship_date_sk, cs_item_sk
),
customer_stats AS (
    SELECT
        c.c_customer_sk,
        SUM(COALESCE(ws.ws_net_paid_inc_tax, 0)) AS total_web_spent,
        SUM(COALESCE(ss.ss_net_paid_inc_tax, 0)) AS total_store_spent
    FROM 
        customer c
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
        LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY
        c.c_customer_sk
),
top_customers AS (
    SELECT
        cs.c_customer_sk,
        cs.total_web_spent + cs.total_store_spent AS total_spent,
        RANK() OVER (ORDER BY cs.total_web_spent + cs.total_store_spent DESC) AS rank
    FROM
        customer_stats cs
    WHERE
        (cs.total_web_spent + cs.total_store_spent) > 1000
)
SELECT
    ca.ca_city,
    COUNT(DISTINCT tc.c_customer_sk) AS num_top_customers,
    AVG(tc.total_spent) AS avg_spent
FROM
    top_customers tc
    JOIN customer_address ca ON tc.c_customer_sk = ca.ca_address_sk
WHERE
    ca.ca_state = 'CA'
GROUP BY
    ca.ca_city
ORDER BY
    avg_spent DESC 
LIMIT 10;
