
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(COALESCE(ws.ws_net_paid_inc_tax, 0)) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
    HAVING 
        SUM(COALESCE(ws.ws_net_paid_inc_tax, 0)) IS NOT NULL
),
top_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        COALESCE(rs.total_sales, 0) AS total_sales,
        (SELECT COUNT(*) FROM ranked_sales r WHERE r.ws_item_sk = i.i_item_sk) AS sales_rank
    FROM 
        item i
    LEFT JOIN 
        ranked_sales rs ON i.i_item_sk = rs.ws_item_sk
    WHERE 
        i.i_rec_start_date <= DATE '2002-10-01' AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date >= DATE '2002-10-01')
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    ti.i_item_id,
    ti.i_product_name,
    ti.total_sales,
    hv.total_spent
FROM 
    top_items ti
JOIN 
    high_value_customers hv ON hv.total_spent > 1000
LEFT JOIN 
    customer c ON c.c_customer_sk = hv.c_customer_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ti.sales_rank <= 10
ORDER BY 
    ti.total_sales DESC
LIMIT 50;
