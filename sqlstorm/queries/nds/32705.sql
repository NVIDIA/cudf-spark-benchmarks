
WITH  sales_data AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_sales, 
        SUM(ws_net_paid) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY ws_item_sk
),
customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    INNER JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE cd.cd_marital_status = 'M'
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
ranked_customers AS (
    SELECT 
        cua.c_customer_sk,
        cua.cd_gender,
        cua.cd_marital_status,
        cua.cd_credit_rating,
        cua.order_count,
        cua.total_spent,
        DENSE_RANK() OVER (ORDER BY cua.total_spent DESC) AS customer_rank
    FROM customer_analysis cua
)
SELECT 
    r.customer_rank,
    r.cd_gender,
    r.cd_marital_status,
    r.cd_credit_rating,
    r.order_count,
    r.total_spent,
    s.total_sales,
    s.total_revenue,
    CASE 
        WHEN r.total_spent > 1000 THEN 'High Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM ranked_customers r
LEFT JOIN sales_data s ON s.ws_item_sk = (
    SELECT item.i_item_sk 
    FROM item item 
    WHERE item.i_current_price IS NOT NULL 
    ORDER BY item.i_current_price DESC
    LIMIT 1
)
WHERE r.customer_rank <= 10
ORDER BY r.total_spent DESC;
