
WITH ranked_sales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS rank
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY ws.ws_item_sk
),
sales_summary AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity,
        COALESCE(NULLIF(i.i_current_price, 0), 1) AS safe_price,
        r.total_quantity * COALESCE(NULLIF(i.i_current_price, 0), 1) AS total_revenue
    FROM ranked_sales r
    JOIN item i ON r.ws_item_sk = i.i_item_sk
    WHERE r.rank <= 10
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cs.total_revenue
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN sales_summary cs ON c.c_customer_sk = cs.ws_item_sk
    WHERE
        cd.cd_marital_status IS NULL OR
        cd.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics WHERE cd_gender = 'F')
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    COALESCE(SUM(cs.total_revenue), 0) AS total_spent,
    COUNT(CASE WHEN ci.cd_marital_status = 'M' THEN 1 END) AS married_count,
    COUNT(CASE WHEN ci.cd_gender = 'F' THEN 1 END) AS female_count,
    MAX(CASE WHEN cs.total_revenue IS NULL THEN 'No Purchase' ELSE 'Purchased' END) AS purchase_status
FROM customer_info ci
LEFT JOIN sales_summary cs ON ci.c_customer_sk = cs.ws_item_sk
GROUP BY ci.c_first_name, ci.c_last_name
HAVING COALESCE(SUM(cs.total_revenue), 0) > 1000 OR COUNT(ci.c_first_name) = 0
ORDER BY total_spent DESC, ci.c_last_name ASC
LIMIT 100;
