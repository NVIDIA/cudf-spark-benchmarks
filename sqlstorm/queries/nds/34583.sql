
WITH  sales_performance AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COALESCE(hd.hd_buy_potential, 'UNKNOWN') AS buy_potential,
        MAX(s.total_net_profit) AS max_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        sales_performance s ON s.ws_sold_date_sk IN (c.c_first_sales_date_sk, c.c_first_shipto_date_sk)
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, hd.hd_buy_potential
),
inventory_check AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    WHERE 
        inv.inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.buy_potential,
    COALESCE(sp.total_net_profit, 0) AS sales_profit,
    COALESCE(ic.total_quantity, 0) AS available_inventory,
    (COALESCE(sp.total_net_profit, 0) / NULLIF(ic.total_quantity, 0)) AS profit_per_item
FROM 
    customer_summary cs
LEFT JOIN 
    sales_performance sp ON cs.c_customer_sk = sp.ws_sold_date_sk
LEFT JOIN 
    inventory_check ic ON cs.max_profit = ic.inv_item_sk
WHERE 
    (cs.buy_potential = 'HIGH' OR cs.buy_potential = 'MEDIUM')
    AND (cs.max_profit IS NOT NULL OR cs.max_profit > 100)
ORDER BY 
    profit_per_item DESC;
