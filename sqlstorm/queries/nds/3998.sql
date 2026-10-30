
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
inventory_data AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM 
        inventory inv
    WHERE 
        inv.inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
    GROUP BY 
        inv.inv_item_sk
),
customer_data AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    i.i_item_id,
    COALESCE(sd.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(id.total_quantity_on_hand, 0) AS total_quantity_on_hand,
    COALESCE(cd.customer_count, 0) AS customer_count,
    COALESCE(cd.avg_purchase_estimate, 0) AS avg_purchase_estimate
FROM 
    item i
LEFT JOIN 
    sales_data sd ON i.i_item_sk = sd.ws_item_sk
LEFT JOIN 
    inventory_data id ON i.i_item_sk = id.inv_item_sk
LEFT JOIN 
    customer_data cd ON cd.customer_count > 0
ORDER BY 
    total_sales DESC
LIMIT 100;
