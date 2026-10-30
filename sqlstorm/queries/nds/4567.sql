WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_purchase
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
),
sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        ci.full_name,
        sd.total_sales,
        sd.order_count,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM customer_info ci
    JOIN sales_data sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
    WHERE ci.rank_by_purchase <= 10
)
SELECT 
    t.full_name,
    t.total_sales,
    t.order_count,
    CASE 
        WHEN t.sales_rank <= 5 THEN 'Top 5 Customers'
        ELSE 'Other Top Customers'
    END AS customer_category
FROM top_customers t
WHERE t.total_sales > 1000 
ORDER BY t.total_sales DESC;