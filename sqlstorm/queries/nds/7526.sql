
WITH sales_summary AS (
    SELECT 
        cd.cd_gender,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        cd.cd_gender
),
inventory_summary AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
profit_analysis AS (
    SELECT 
        iss.i_item_sk,
        iss.i_item_id,
        COALESCE(ss.total_quantity, 0) AS total_sales_quantity,
        COALESCE(ss.total_profit, 0) AS total_sales_profit,
        COALESCE(isu.total_inventory, 0) AS total_inventory
    FROM 
        item iss
    LEFT JOIN 
        sales_summary ss ON iss.i_item_sk = ss.total_quantity
    LEFT JOIN 
        inventory_summary isu ON iss.i_item_sk = isu.inv_item_sk
)
SELECT 
    pa.i_item_id,
    pa.total_sales_quantity,
    pa.total_sales_profit,
    pa.total_inventory,
    (CASE 
        WHEN pa.total_inventory = 0 THEN 0 
        ELSE pa.total_sales_profit / pa.total_inventory 
    END) AS profit_per_inventory_unit
FROM 
    profit_analysis pa
ORDER BY 
    profit_per_inventory_unit DESC
LIMIT 10;
