
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2458850 AND 2458880
    GROUP BY 
        ws_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2458850 AND 2458880
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
),
top_items AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_sales,
        ROW_NUMBER() OVER (ORDER BY rs.total_sales DESC) AS rank
    FROM 
        ranked_sales rs
    WHERE 
        rs.order_count > 1
    LIMIT 10
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    ti.ws_item_sk,
    ti.total_sales
FROM 
    customer_summary cs
JOIN 
    top_items ti ON cs.total_orders > 2
ORDER BY 
    ti.total_sales DESC, cs.c_last_name, cs.c_first_name;
