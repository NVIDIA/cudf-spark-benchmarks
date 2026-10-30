WITH sales_info AS (
    SELECT 
        w.w_warehouse_id, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1500 AND 1550
    GROUP BY 
        w.w_warehouse_id
),
customer_info AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, 
        cd.cd_gender
),
inventory_info AS (
    SELECT 
        i.i_item_id, 
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    JOIN 
        item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_id
),
detailed_report AS (
    SELECT 
        si.w_warehouse_id, 
        ci.cd_gender,
        ci.customer_count, 
        ci.avg_purchase_estimate,
        ii.total_inventory,
        si.total_quantity,
        si.total_profit,
        si.total_orders,
        si.avg_sales_price
    FROM 
        sales_info si
    JOIN 
        customer_info ci ON si.total_orders > 10  
    JOIN 
        inventory_info ii ON ii.total_inventory < 100  
)
SELECT 
    *,
    (total_profit / NULLIF(total_orders, 0)) AS profit_per_order
FROM 
    detailed_report
ORDER BY 
    total_profit DESC;