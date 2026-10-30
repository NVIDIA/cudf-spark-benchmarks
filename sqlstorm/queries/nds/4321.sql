
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count,
        MAX(ws.ws_sales_price) AS max_sales_price,
        MIN(ws.ws_sales_price) AS min_sales_price
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM 
        customer_sales cs
    WHERE 
        cs.total_spent > 1000
), 
customer_categories AS (
    SELECT 
        hvc.c_customer_sk,
        CASE 
            WHEN cd.cd_gender = 'F' AND cc.cc_division_name = 'High' THEN 'Top Female Customers'
            WHEN cd.cd_gender = 'M' AND cc.cc_division_name = 'Medium' THEN 'Mid Male Customers'
            ELSE 'Other'
        END AS customer_category
    FROM 
        high_value_customers hvc
    JOIN 
        customer_demographics cd ON hvc.c_customer_sk = cd.cd_demo_sk
    JOIN 
        call_center cc ON cd.cd_demo_sk = cc.cc_call_center_sk
)
SELECT 
    hc.c_customer_sk,
    cc.customer_category,
    hc.total_spent,
    hc.order_count,
    hc.c_first_name,
    hc.c_last_name,
    hc.customer_rank,
    CASE 
        WHEN cc.customer_category = 'Top Female Customers' THEN 'Gold'
        WHEN cc.customer_category = 'Mid Male Customers' THEN 'Silver'
        ELSE 'Bronze'
    END AS tier_level
FROM 
    high_value_customers hc
JOIN 
    customer_categories cc ON hc.c_customer_sk = cc.c_customer_sk
ORDER BY 
    tier_level, hc.total_spent DESC
LIMIT 50;
