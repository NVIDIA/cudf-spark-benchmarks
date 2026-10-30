
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
sales_summary AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) as total_quantity_sold,
        SUM(ws.ws_net_profit) as total_net_profit
    FROM 
        web_sales ws
    JOIN 
        ranked_customers rc ON ws.ws_bill_customer_sk = rc.c_customer_sk
    WHERE 
        rc.rnk <= 10
    GROUP BY 
        ws.ws_item_sk
),
inventory_check AS (
    SELECT 
        i.i_item_sk,
        COALESCE(inv.inv_quantity_on_hand, 0) as available_stock
    FROM 
        item i
    LEFT JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk
)
SELECT 
    i.i_item_id, 
    i.i_item_desc, 
    sc.total_quantity_sold, 
    COALESCE(sc.total_net_profit, 0) AS total_net_profit,
    ic.available_stock,
    CASE 
        WHEN ic.available_stock < 10 THEN 'Low Stock' 
        ELSE 'Sufficient Stock' 
    END AS stock_status
FROM 
    item i
LEFT JOIN 
    sales_summary sc ON i.i_item_sk = sc.ws_item_sk
JOIN 
    inventory_check ic ON i.i_item_sk = ic.i_item_sk
WHERE 
    EXISTS (
        SELECT 1 
        FROM promotion p 
        WHERE p.p_item_sk = i.i_item_sk 
        AND p.p_discount_active = 'Y'
    )
ORDER BY 
    sc.total_net_profit DESC NULLS LAST;
