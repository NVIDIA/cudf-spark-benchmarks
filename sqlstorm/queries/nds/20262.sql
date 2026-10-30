
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank,
        MAX(ws_sold_date_sk) AS last_sale_date
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
    GROUP BY 
        ws_item_sk
),
high_sales AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity,
        r.last_sale_date,
        COALESCE(cd_marital_status, 'Unknown') AS marital_status,
        DENSE_RANK() OVER (ORDER BY r.total_quantity DESC) AS quantity_rank
    FROM 
        ranked_sales r
    LEFT JOIN 
        customer c ON r.ws_item_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        r.sales_rank = 1
),
low_inventory AS (
    SELECT 
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        DENSE_RANK() OVER (ORDER BY inv.inv_quantity_on_hand ASC) AS inventory_rank
    FROM 
        inventory inv
    WHERE 
        inv.inv_quantity_on_hand < 10
),
final_report AS (
    SELECT 
        hs.ws_item_sk,
        hs.total_quantity,
        hs.last_sale_date,
        li.inv_quantity_on_hand,
        hs.marital_status,
        (CASE 
            WHEN li.inv_quantity_on_hand IS NULL THEN 'In Stock'
            WHEN li.inv_quantity_on_hand = 0 THEN 'Out of Stock'
            ELSE 'Low Stock'
        END) AS stock_status,
        (SELECT COUNT(*) 
         FROM catalog_sales cs 
         WHERE cs.cs_item_sk = hs.ws_item_sk 
           AND cs.cs_sold_date_sk = hs.last_sale_date) AS catalog_sales_today
    FROM 
        high_sales hs
    LEFT JOIN 
        low_inventory li ON hs.ws_item_sk = li.inv_item_sk
)
SELECT 
    f.ws_item_sk,
    f.total_quantity,
    f.last_sale_date,
    f.inv_quantity_on_hand,
    f.marital_status,
    f.stock_status,
    f.catalog_sales_today
FROM 
    final_report f
WHERE 
    f.stock_status IN ('Low Stock', 'Out of Stock')
ORDER BY 
    f.total_quantity DESC
LIMIT 50;
