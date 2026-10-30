
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
high_value_customers AS (
    SELECT 
        ci.c_customer_sk, 
        ci.c_first_name, 
        ci.c_last_name
    FROM 
        customer_info ci
    WHERE 
        ci.cd_purchase_estimate > (
            SELECT AVG(cd_purchase_estimate) 
            FROM customer_demographics
        )
),
sales_summary AS (
    SELECT 
        r.ws_item_sk,
        SUM(r.ws_sales_price) AS total_sales_price,
        COUNT(*) AS sales_count
    FROM 
        ranked_sales r
    JOIN 
        high_value_customers hvc ON r.ws_order_number IN (
            SELECT ws_order_number 
            FROM web_sales 
            WHERE ws_bill_customer_sk = hvc.c_customer_sk
        )
    GROUP BY r.ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(ss.total_sales_price, 0) AS total_sales_price,
    COALESCE(ss.sales_count, 0) AS sales_count,
    CASE 
        WHEN ss.total_sales_price > 1000 THEN 'High Performer'
        ELSE 'Regular Performer' 
    END AS performance_category
FROM 
    item i
LEFT JOIN 
    sales_summary ss ON i.i_item_sk = ss.ws_item_sk
WHERE 
    i.i_current_price IS NOT NULL
ORDER BY 
    total_sales_price DESC, 
    i.i_item_desc
LIMIT 100;
