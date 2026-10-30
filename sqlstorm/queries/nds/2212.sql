
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        cd.cd_gender,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY ws.ws_net_profit DESC) AS gender_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
),
TopSales AS (
    SELECT 
        sd.ws_order_number,
        sd.ws_item_sk,
        sd.ws_sales_price,
        sd.ws_quantity,
        sd.ws_net_profit,
        sd.cd_gender
    FROM 
        SalesData sd
    WHERE 
        sd.gender_rank <= 5
),
WarehouseInventory AS (
    SELECT 
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        w.w_warehouse_name
    FROM 
        inventory inv
    JOIN 
        warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
)
SELECT 
    ts.ws_order_number,
    ts.ws_item_sk,
    ts.ws_sales_price,
    ts.ws_quantity,
    ts.ws_net_profit,
    wi.inv_quantity_on_hand,
    wi.w_warehouse_name
FROM 
    TopSales ts
LEFT JOIN 
    WarehouseInventory wi ON ts.ws_item_sk = wi.inv_item_sk
WHERE 
    wi.inv_quantity_on_hand IS NOT NULL
ORDER BY 
    ts.ws_net_profit DESC, 
    ts.ws_sales_price ASC
LIMIT 10;
