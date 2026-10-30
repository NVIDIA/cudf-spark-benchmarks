
WITH ranked_sales AS (
    SELECT 
        c.c_customer_id,
        w.w_warehouse_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        c.c_customer_id, w.w_warehouse_id
),
top_sales AS (
    SELECT 
        c_customer_id,
        w_warehouse_id,
        total_quantity,
        total_sales
    FROM 
        ranked_sales
    WHERE 
        sales_rank = 1
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_credit_rating,
    ts.w_warehouse_id,
    ts.total_quantity,
    ts.total_sales
FROM 
    top_sales ts
JOIN 
    customer_info ci ON ts.c_customer_id = ci.c_customer_id
ORDER BY 
    ts.total_sales DESC
LIMIT 100;
