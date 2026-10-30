
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_id
),
WarehouseInventory AS (
    SELECT 
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_warehouse_sk
),
SalesOverTime AS (
    SELECT 
        d.d_year, 
        SUM(ws.ws_ext_sales_price) AS yearly_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    cs.c_customer_id,
    cs.total_sales,
    cs.order_count,
    wi.total_inventory,
    sot.yearly_sales
FROM 
    CustomerSales cs
JOIN 
    WarehouseInventory wi ON wi.inv_warehouse_sk IN (SELECT s.s_store_sk FROM store s WHERE s.s_number_employees > 50)
JOIN 
    SalesOverTime sot ON sot.yearly_sales > 1000000
ORDER BY 
    cs.total_sales DESC
LIMIT 10;
