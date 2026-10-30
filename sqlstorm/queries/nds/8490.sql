
WITH CustomerWebSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
HighValueCustomers AS (
    SELECT 
        cws.c_customer_id,
        cws.total_web_sales,
        cws.total_orders
    FROM 
        CustomerWebSales cws
    WHERE 
        cws.total_web_sales > (SELECT AVG(total_web_sales) FROM CustomerWebSales)
),
WarehouseInventory AS (
    SELECT 
        i.i_item_id,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    JOIN 
        item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_id
),
FetchedItems AS (
    SELECT 
        hi.c_customer_id,
        w_inv.i_item_id,
        hi.total_web_sales,
        hi.total_orders,
        w_inv.total_quantity
    FROM 
        HighValueCustomers hi
    JOIN 
        WarehouseInventory w_inv ON (hi.total_web_sales / hi.total_orders) > 100
)
SELECT 
    f.c_customer_id,
    f.i_item_id,
    f.total_web_sales,
    f.total_orders,
    f.total_quantity
FROM 
    FetchedItems f
ORDER BY 
    f.total_web_sales DESC
LIMIT 100;
