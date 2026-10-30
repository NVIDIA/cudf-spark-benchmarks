
WITH  top_items AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales 
    FROM web_sales 
    GROUP BY ws_item_sk 
    HAVING SUM(ws_sales_price) > 1000
),
sales_with_rank AS (
    SELECT 
        ti.ws_item_sk,
        ti.total_sales,
        RANK() OVER (ORDER BY ti.total_sales DESC) AS sales_rank 
    FROM top_items ti
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        COUNT(CASE WHEN ws_item_sk IS NOT NULL THEN 1 END) AS item_count 
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating, cd.cd_dep_count
),
high_value_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        SUM(wp.wp_char_count) AS total_char_count,
        AVG(COALESCE(cd.cd_purchase_estimate, 0)) AS avg_purchase_estimate 
    FROM customer_info ci
    JOIN web_page wp ON ci.c_customer_sk = wp.wp_customer_sk 
    LEFT JOIN customer_demographics cd ON ci.c_customer_sk = cd.cd_demo_sk 
    GROUP BY ci.c_customer_sk, ci.c_first_name, ci.c_last_name
    HAVING AVG(COALESCE(cd.cd_purchase_estimate, 0)) > 50000
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_credit_rating,
    ci.item_count,
    COALESCE(hi.total_char_count, 0) AS total_char_count,
    COALESCE(hi.avg_purchase_estimate, 0) AS avg_purchase_estimate,
    tr.total_sales
FROM customer_info ci
LEFT JOIN high_value_customers hi ON ci.c_customer_sk = hi.c_customer_sk
INNER JOIN sales_with_rank tr ON ci.item_count > 5
WHERE ci.cd_gender = 'F' 
AND ci.cd_marital_status = 'M' 
ORDER BY tr.total_sales DESC, hi.avg_purchase_estimate DESC
LIMIT 100;
