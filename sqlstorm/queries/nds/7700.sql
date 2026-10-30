
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) - 30 FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_item_sk
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
top_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        SUM(rs.total_sales) AS total_spent
    FROM 
        customer_info ci
    JOIN 
        ranked_sales rs ON ci.c_customer_sk = rs.ws_item_sk
    WHERE 
        rs.sales_rank <= 10
    GROUP BY 
        ci.c_customer_sk, ci.c_first_name, ci.c_last_name
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
    SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count
FROM 
    top_customers tc
JOIN 
    customer_info ci ON tc.c_customer_sk = ci.c_customer_sk
JOIN 
    web_sales ws ON ws.ws_bill_customer_sk = tc.c_customer_sk
JOIN 
    customer_demographics cd ON ci.c_customer_sk = cd.cd_demo_sk
GROUP BY 
    tc.c_customer_sk, tc.c_first_name, tc.c_last_name, tc.total_spent
ORDER BY 
    tc.total_spent DESC
LIMIT 50;
