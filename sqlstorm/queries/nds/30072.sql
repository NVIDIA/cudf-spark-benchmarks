
WITH  CustomerCTE AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_first_name) as rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
),
SalesCTE AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        AVG(ws.ws_ext_tax) AS avg_tax
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_sold_date_sk
),
InventoryCTE AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand,
        COUNT(DISTINCT inv.inv_warehouse_sk) AS warehouse_count
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    ccte.c_first_name,
    ccte.c_last_name,
    ccte.cd_gender,
    COALESCE(sc.total_sales, 0) AS total_sales,
    ic.total_on_hand,
    ic.warehouse_count,
    (SELECT COUNT(*) 
     FROM store s 
     WHERE s.s_division_name = 'Electronics') AS electronics_stores,
    CASE 
        WHEN ic.total_on_hand > 100 THEN 'Stocked'
        ELSE 'Low Stock'
    END AS stock_status
FROM 
    CustomerCTE ccte
LEFT JOIN 
    SalesCTE sc ON ccte.rn = sc.ws_sold_date_sk
JOIN 
    InventoryCTE ic ON ic.inv_item_sk = ccte.c_customer_sk
ORDER BY 
    ccte.c_last_name, 
    ccte.c_first_name;

