
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id
),
high_value_customers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 10000
),
customer_analysis AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        hvc.cd_gender,
        hvc.cd_marital_status,
        hvc.cd_purchase_estimate,
        CASE 
            WHEN cs.total_sales > 50000 THEN 'High Value'
            WHEN cs.total_sales BETWEEN 20000 AND 50000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM customer_sales cs
    LEFT JOIN high_value_customers hvc ON cs.c_customer_id = hvc.c_customer_id
)
SELECT 
    ca.c_customer_id,
    ca.total_sales,
    ca.customer_value,
    COUNT(CASE WHEN ca.cd_gender IS NULL THEN 1 END) AS gender_null_count,
    AVG(ca.cd_purchase_estimate) AS avg_purchase_estimate
FROM customer_analysis ca
GROUP BY ca.c_customer_id, ca.total_sales, ca.customer_value
HAVING AVG(ca.cd_purchase_estimate) IS NOT NULL
ORDER BY ca.total_sales DESC
LIMIT 100;
