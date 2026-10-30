
WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_order_number
),
top_sales AS (
    SELECT 
        ws_item_sk,
        MAX(total_sales) AS max_sales
    FROM 
        sales_summary
    WHERE 
        rn <= 5
    GROUP BY 
        ws_item_sk
),
customer_info AS (
    SELECT 
        c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c_customer_sk
),
demographic_info AS (
    SELECT 
        cd_gender,
        SUM(order_count) AS total_orders,
        SUM(total_spent) AS total_spending
    FROM 
        customer_info ci
    JOIN customer_demographics cd ON ci.c_customer_sk = cd.cd_demo_sk
    GROUP BY cd_gender
)
SELECT 
    d.cd_gender,
    d.total_orders,
    d.total_spending,
    COALESCE(t.max_sales, 0) AS highest_sales
FROM 
    demographic_info d
LEFT JOIN 
    top_sales t ON d.total_spending = t.max_sales
WHERE 
    d.total_orders > 10
ORDER BY 
    d.total_spending DESC;
