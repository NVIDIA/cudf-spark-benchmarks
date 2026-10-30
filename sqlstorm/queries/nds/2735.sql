WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER(PARTITION BY cd.cd_gender ORDER BY total_sales DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_sales cs ON c.c_customer_sk = cs.c_customer_sk
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM customer_sales)
)
SELECT 
    hvc.c_customer_sk,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.cd_purchase_estimate,
    cs.total_sales,
    cs.order_count
FROM 
    high_value_customers hvc
JOIN 
    customer_sales cs ON hvc.c_customer_sk = cs.c_customer_sk
WHERE 
    hvc.rank <= 10
ORDER BY 
    hvc.cd_gender, cs.total_sales DESC;