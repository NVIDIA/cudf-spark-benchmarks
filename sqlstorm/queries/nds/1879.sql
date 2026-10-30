WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= 2459580 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
demographics_info AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE 
            WHEN cd.cd_purchase_estimate > 500 THEN 'High'
            WHEN cd.cd_purchase_estimate BETWEEN 200 AND 500 THEN 'Medium'
            ELSE 'Low'
        END AS purchase_category
    FROM 
        customer_demographics cd
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_sales,
    cs.order_count,
    cs.avg_order_value,
    di.cd_gender,
    di.cd_marital_status,
    di.purchase_category,
    ROW_NUMBER() OVER (PARTITION BY di.purchase_category ORDER BY cs.total_sales DESC) AS rank
FROM 
    customer_sales cs
LEFT JOIN 
    demographics_info di ON cs.c_customer_sk = di.cd_demo_sk
WHERE 
    cs.total_sales IS NOT NULL
ORDER BY 
    cs.total_sales DESC
LIMIT 10;