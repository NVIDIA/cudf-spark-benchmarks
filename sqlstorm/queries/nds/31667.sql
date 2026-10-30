
WITH  sales_hierarchy AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk > (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY ws_item_sk
), 
top_sales AS (
    SELECT 
        sh.ws_item_sk, 
        sh.total_sales,
        ROW_NUMBER() OVER (ORDER BY sh.total_sales DESC) AS rank
    FROM 
        sales_hierarchy sh
    WHERE 
        sh.rn = 1
    LIMIT 10
),
inventory_check AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        CASE 
            WHEN SUM(inv.inv_quantity_on_hand) IS NULL THEN 'No Inventory'
            ELSE 'In Stock'
        END AS inventory_status
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    ts.ws_item_sk,
    ts.total_sales,
    ic.total_inventory,
    ic.inventory_status,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status
FROM 
    top_sales ts
LEFT JOIN 
    inventory_check ic ON ts.ws_item_sk = ic.inv_item_sk
LEFT JOIN 
    web_sales ws ON ts.ws_item_sk = ws.ws_item_sk
LEFT JOIN 
    customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
WHERE 
    (cd.cd_marital_status = 'M' OR cd.cd_gender = 'F') 
    AND (ic.total_inventory IS NOT NULL OR ts.total_sales > 1000)
ORDER BY 
    ts.total_sales DESC;
