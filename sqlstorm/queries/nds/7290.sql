WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2459608 AND 2459618 
    GROUP BY 
        ws_item_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_expenditure
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
WarehouseData AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory 
    JOIN 
        warehouse w ON inventory.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk
)
SELECT 
    sd.ws_item_sk,
    sd.total_quantity,
    sd.total_sales,
    cd.total_orders,
    cd.total_expenditure,
    wd.total_inventory
FROM 
    SalesData sd
LEFT JOIN 
    CustomerData cd ON sd.ws_item_sk = cd.c_customer_sk
LEFT JOIN 
    WarehouseData wd ON sd.ws_item_sk = wd.w_warehouse_sk
ORDER BY 
    sd.total_sales DESC
LIMIT 100;