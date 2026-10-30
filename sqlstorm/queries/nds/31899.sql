
WITH  sales_ranking AS (
    SELECT 
        ss_customer_sk,
        ss_item_sk,
        SUM(ss_net_paid) AS total_sales,
        RANK() OVER (PARTITION BY ss_customer_sk ORDER BY SUM(ss_net_paid) DESC) AS rank
    FROM store_sales
    GROUP BY ss_customer_sk, ss_item_sk
),
top_items AS (
    SELECT 
        sr.ss_customer_sk,
        sr.ss_item_sk,
        sr.total_sales
    FROM sales_ranking sr
    WHERE sr.rank <= 5
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(sr.total_sales) AS total_spent
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN top_items sr ON c.c_customer_sk = sr.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
sales_summary AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        COALESCE(ci.cd_gender, 'U') AS gender,
        COALESCE(ci.cd_marital_status, 'N') AS marital_status,
        COALESCE(ci.cd_credit_rating, 'Unknown') AS credit_rating,
        ci.total_spent,
        COUNT(ti.ss_item_sk) AS total_items,
        AVG(ti.total_sales) AS avg_sales_per_item
    FROM customer_info ci
    JOIN top_items ti ON ci.c_customer_sk = ti.ss_customer_sk
    WHERE ci.total_spent > 0
    GROUP BY ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender, ci.cd_marital_status, ci.cd_credit_rating, ci.total_spent
)
SELECT 
    ss.c_customer_sk,
    ss.c_first_name,
    ss.c_last_name,
    ss.gender,
    ss.marital_status,
    ss.credit_rating,
    ss.total_spent,
    ss.total_items,
    ss.avg_sales_per_item
FROM sales_summary ss
WHERE ss.total_spent > (
    SELECT AVG(total_spent) FROM sales_summary
    WHERE total_spent IS NOT NULL
) 
UNION ALL
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    COALESCE(ci.cd_gender, 'U') AS gender,
    COALESCE(ci.cd_marital_status, 'N') AS marital_status,
    COALESCE(ci.cd_credit_rating, 'Unknown') AS credit_rating,
    0 AS total_spent,
    0 AS total_items,
    0 AS avg_sales_per_item
FROM customer_info ci
WHERE NOT EXISTS (
    SELECT 1 FROM top_items ti WHERE ci.c_customer_sk = ti.ss_customer_sk
)
ORDER BY total_spent DESC, c_customer_sk;
