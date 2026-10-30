
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_sales_price DESC) AS rank_price
    FROM 
        web_sales
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        SUM(rs.ws_quantity * rs.ws_sales_price) AS total_sales,
        COUNT(rs.ws_item_sk) AS total_items_sold,
        AVG(rs.ws_sales_price) AS avg_item_price
    FROM 
        ranked_sales rs
    JOIN 
        customer_info ci ON rs.ws_bill_customer_sk = ci.c_customer_sk
    WHERE 
        rs.rank_price <= 5 
    GROUP BY 
        ci.c_customer_sk, ci.c_first_name, ci.c_last_name
)
SELECT 
    css.c_customer_sk,
    css.c_first_name,
    css.c_last_name,
    css.total_sales,
    css.total_items_sold,
    CASE 
        WHEN css.total_sales > 1000 THEN 'Premium'
        WHEN css.total_sales BETWEEN 500 AND 1000 THEN 'Mid Tier'
        ELSE 'Budget'
    END AS customer_tier
FROM 
    sales_summary css
LEFT JOIN 
    store s ON css.total_items_sold > 10
WHERE 
    css.total_sales IS NOT NULL
ORDER BY 
    css.total_sales DESC
LIMIT 10;
