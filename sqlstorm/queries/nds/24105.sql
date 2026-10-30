
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS rank_by_spending
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
high_spenders AS (
    SELECT 
        cs.c_customer_sk, 
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.total_spent,
        cs.total_discount,
        cs.rank_by_spending
    FROM 
        customer_summary cs
    WHERE 
        cs.rank_by_spending <= 10
),
inventory_summary AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand,
        COUNT(DISTINCT inv.inv_warehouse_sk) AS total_warehouses
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    h.c_first_name,
    h.c_last_name,
    h.cd_gender,
    i.inv_item_sk,
    COALESCE(h.total_spent, 0) AS total_spent,
    COALESCE(h.total_discount, 0) AS total_discount,
    COALESCE(i.total_quantity_on_hand, 0) AS quantity_on_hand,
    CASE 
        WHEN i.total_quantity_on_hand IS NULL OR i.total_quantity_on_hand = 0 THEN 'Out of stock'
        ELSE 'In stock'
    END AS stock_status,
    (SELECT 
        COUNT(DISTINCT sr.sr_ticket_number) 
     FROM 
        store_returns sr 
     WHERE 
        sr.sr_customer_sk = h.c_customer_sk 
        AND sr.sr_return_quantity > 0) AS return_count
FROM 
    high_spenders h
FULL OUTER JOIN 
    inventory_summary i ON h.c_customer_sk = i.inv_item_sk
WHERE 
    (h.cd_gender IS NOT NULL OR h.total_spent > 100) 
    AND (i.total_warehouses > 5 OR i.total_quantity_on_hand IS NULL)
ORDER BY 
    h.total_spent DESC, 
    h.c_last_name ASC;
