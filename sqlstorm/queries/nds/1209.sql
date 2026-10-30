WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 0
),
date_range AS (
    SELECT 
        MIN(d.d_date) AS min_date, 
        MAX(d.d_date) AS max_date
    FROM 
        date_dim d
    WHERE 
        d.d_year = 2000
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id, i.i_product_name
),
sales_summary AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_sales_price) AS store_sales
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_item_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    dr.min_date,
    dr.max_date,
    id.i_product_name,
    COALESCE(id.total_quantity_sold, 0) AS web_sales_quantity,
    COALESCE(ss.store_quantity, 0) AS store_sales_quantity,
    COALESCE(id.total_sales, 0) AS web_sales_total,
    COALESCE(ss.store_sales, 0) AS store_sales_total,
    CASE 
        WHEN COALESCE(id.total_sales, 0) > COALESCE(ss.store_sales, 0) THEN 'Web Sales Higher'
        ELSE 'Store Sales Higher or Equal'
    END AS sales_comparison
FROM 
    customer_stats cs
CROSS JOIN 
    date_range dr
LEFT JOIN 
    item_details id ON cs.c_customer_sk = id.i_item_sk  
LEFT JOIN 
    sales_summary ss ON id.i_item_sk = ss.ss_item_sk
WHERE 
    cs.rank <= 10
ORDER BY 
    cs.rank, id.i_product_name;