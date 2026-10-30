
WITH ranked_sales AS (
    SELECT 
        cs_item_sk,
        cs_sales_price,
        cs_quantity,
        RANK() OVER (PARTITION BY cs_item_sk ORDER BY cs_sales_price DESC) AS sales_rank
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2459980 AND 2463623
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COALESCE(NULLIF(cd.cd_purchase_estimate, 0), -1) AS purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    SUM(r.cs_sales_price * r.cs_quantity) AS total_spent,
    COUNT(r.cs_item_sk) AS total_items_purchased,
    MAX(r.cs_sales_price) AS highest_item_price,
    CASE 
        WHEN ci.purchase_estimate > 1000 THEN 'High Value'
        WHEN ci.purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM ranked_sales r
JOIN customer_info ci ON ci.c_customer_sk IN (
    SELECT sr_customer_sk 
    FROM store_returns 
    WHERE sr_return_quantity > 0
)
GROUP BY 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.purchase_estimate
HAVING 
    SUM(r.cs_sales_price * r.cs_quantity) > 0
ORDER BY 
    total_spent DESC
LIMIT 10;
