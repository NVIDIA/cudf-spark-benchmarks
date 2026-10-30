
WITH  sales_cte AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        ss_store_sk, ss_item_sk
), 
top_items AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        total_sales
    FROM 
        sales_cte
    WHERE 
        sales_rank <= 5
), 
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(sc.total_sales, 0) AS total_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        (SELECT 
            ss_store_sk, ss_item_sk, SUM(ss_sales_price) AS total_sales 
         FROM 
            store_sales 
         GROUP BY 
            ss_store_sk, ss_item_sk) AS sc ON c.c_customer_sk = sc.ss_item_sk
), 
combined_info AS (
    SELECT 
        ci.c_customer_id,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        ti.total_sales
    FROM 
        customer_info ci
    JOIN 
        top_items ti ON ci.total_sales = ti.total_sales
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    COALESCE(AVG(ci.cd_purchase_estimate), 0) AS avg_purchase_estimate,
    SUM(ti.total_sales) AS total_sales_amount,
    COUNT(DISTINCT ti.ss_item_sk) AS unique_items_purchased
FROM 
    combined_info ci
JOIN 
    top_items ti ON ci.total_sales = ti.total_sales
GROUP BY 
    ci.c_customer_id, ci.cd_gender, ci.cd_marital_status
HAVING 
    SUM(ti.total_sales) > 1000
ORDER BY 
    total_sales_amount DESC;
