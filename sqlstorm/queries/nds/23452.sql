
WITH  customer_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_dep_count,
        cd.cd_dep_college_count,
        c.c_birth_year,
        c.c_birth_month,
        c.c_birth_day,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year DESC) AS row_num
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
years AS (
    SELECT DISTINCT 
        d.d_year AS year
    FROM 
        date_dim d 
    WHERE 
        d.d_year BETWEEN 2000 AND 2023
),
top_items AS (
    SELECT 
        i.i_item_sk,
        SUM(ws.ws_quantity) AS total_sales
    FROM 
        item i 
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year IN (SELECT year FROM years))
    GROUP BY 
        i.i_item_sk
    ORDER BY 
        total_sales DESC
    LIMIT 10
)
SELECT 
    ch.c_customer_sk,
    ch.c_first_name,
    ch.c_last_name,
    COALESCE(ch.cd_gender, 'Unknown') AS gender,
    SUM(ti.total_sales) AS top_items_sales,
    COUNT(CASE WHEN ch.row_num = 1 THEN 1 END) AS is_youngest,
    MAX(CASE WHEN ti.total_sales IS NULL THEN 'Out of Stock' ELSE 'In Stock' END) AS stock_status
FROM 
    customer_hierarchy ch 
LEFT JOIN 
    top_items ti ON ch.c_customer_sk = ti.i_item_sk
LEFT JOIN 
    inventory inv ON ti.i_item_sk = inv.inv_item_sk AND inv.inv_quantity_on_hand > 0
GROUP BY 
    ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ch.cd_gender
HAVING 
    SUM(ti.total_sales) > 1000 OR COUNT(ch.c_birth_year) = 0
ORDER BY 
    top_items_sales DESC, ch.c_last_name;
