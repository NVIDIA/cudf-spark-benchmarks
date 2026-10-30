
WITH CustomerOrders AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_sold_date_sk) AS last_order_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 AND 
                                    (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        c.c_customer_id
),
HighSpenders AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        co.total_spent,
        co.order_count,
        DENSE_RANK() OVER (ORDER BY co.total_spent DESC) AS spend_rank
    FROM 
        customer c
    JOIN 
        CustomerOrders co ON c.c_customer_id = co.c_customer_id
    WHERE 
        co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
),
WarehouseInventory AS (
    SELECT 
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    JOIN 
        warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE 
        w.w_state = 'CA'
    GROUP BY 
        inv.inv_warehouse_sk
)
SELECT 
    hs.c_customer_sk,
    hs.c_first_name,
    hs.c_last_name,
    hs.total_spent,
    hs.order_count,
    wi.total_inventory
FROM 
    HighSpenders hs
JOIN 
    WarehouseInventory wi ON wi.inv_warehouse_sk IN (SELECT w_warehouse_sk FROM warehouse)
WHERE 
    hs.spend_rank <= 10
ORDER BY 
    hs.total_spent DESC;
