WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_ext_discount_amt) AS avg_discount,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS item_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
inventory_status AS (
    SELECT 
        inv_date_sk,
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_stock
    FROM 
        inventory
    GROUP BY 
        inv_date_sk, inv_item_sk
),
date_filter AS (
    SELECT 
        d_date_sk 
    FROM 
        date_dim 
    WHERE 
        d_date BETWEEN '2001-01-01' AND '2001-12-31'
)
SELECT 
    ci.c_customer_id,
    ss.ws_sold_date_sk,
    ss.total_quantity,
    ss.total_sales,
    ss.avg_discount,
    inv.total_stock,
    CASE 
        WHEN inv.total_stock IS NULL THEN 'Out of Stock'
        WHEN ss.total_quantity >= inv.total_stock THEN 'Low Stock'
        ELSE 'In Stock'
    END AS stock_status
FROM 
    customer_info ci
JOIN 
    sales_summary ss ON ci.rn = (CASE WHEN ci.cd_gender = 'F' THEN 1 ELSE 2 END)  
LEFT JOIN 
    inventory_status inv ON ss.ws_item_sk = inv.inv_item_sk AND ss.ws_sold_date_sk = inv.inv_date_sk
JOIN 
    date_filter df ON ss.ws_sold_date_sk = df.d_date_sk
WHERE 
    ss.item_rank = 1
ORDER BY 
    ss.total_sales DESC, ci.c_customer_id;