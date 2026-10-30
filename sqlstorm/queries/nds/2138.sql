
WITH ranked_sales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales, 
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450000 AND 2450050
    GROUP BY 
        ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    WHERE 
        cd.cd_purchase_estimate > 50 
        AND cd.cd_gender IS NOT NULL
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
top_items AS (
    SELECT 
        i.i_item_id, 
        i.i_item_desc, 
        r.total_sales
    FROM 
        item i
    JOIN 
        ranked_sales r ON i.i_item_sk = r.ws_item_sk
    WHERE 
        r.sales_rank <= 5
)
SELECT 
    ci.c_customer_id, 
    ci.cd_gender, 
    ci.cd_marital_status, 
    ti.i_item_id, 
    ti.i_item_desc, 
    ti.total_sales
FROM 
    customer_info ci
LEFT JOIN 
    top_items ti ON ci.order_count > 5
WHERE 
    ci.cd_marital_status = 'M' 
    OR (ci.cd_marital_status IS NULL AND ci.cd_gender = 'F')
ORDER BY 
    ti.total_sales DESC, 
    ci.c_customer_id
LIMIT 10 OFFSET 10;
