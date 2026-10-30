
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER(PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
customer_sales AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        coalesce(sd.total_sales, 0) AS total_sales,
        coalesce(sd.total_orders, 0) AS total_orders,
        ri.r_reason_desc
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_data sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
    LEFT JOIN 
        (SELECT r.r_reason_sk, r.r_reason_desc FROM reason r) ri ON ri.r_reason_sk IS NULL
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_sales,
    cs.total_orders,
    CASE 
        WHEN cs.total_sales > 1000 THEN 'High Value Customer'
        WHEN cs.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_category
FROM 
    customer_sales cs
WHERE 
    (cs.total_sales > 0 OR cs.total_orders > 0) 
    AND cs.total_orders > (SELECT AVG(total_orders) FROM sales_data)
ORDER BY 
    cs.total_sales DESC;
