
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) - 30 FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_item_sk
),
CustomerGender AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c_customer_sk,
        cd_gender
),
InventoryStatus AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT inv_warehouse_sk) AS warehouse_count
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
)
SELECT 
    S.ws_item_sk,
    S.total_sales,
    C.cd_gender,
    C.total_orders,
    C.total_spent,
    I.total_inventory,
    I.warehouse_count,
    CASE 
        WHEN S.sales_rank <= 10 THEN 'Top 10 Seller'
        ELSE 'Other'
    END AS Sales_Category
FROM 
    SalesCTE S
LEFT JOIN 
    CustomerGender C ON S.ws_item_sk = C.c_customer_sk
JOIN 
    InventoryStatus I ON S.ws_item_sk = I.inv_item_sk
WHERE 
    (C.total_orders IS NULL OR C.total_spent > 1000) 
    AND (I.total_inventory IS NOT NULL AND I.total_inventory > 0)
ORDER BY 
    S.total_sales DESC, C.total_spent DESC;
