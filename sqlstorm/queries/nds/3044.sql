
WITH CustomerProfit AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
), HighValueCustomers AS (
    SELECT 
        cp.c_customer_sk,
        cp.c_first_name,
        cp.c_last_name,
        cp.total_profit
    FROM CustomerProfit cp
    WHERE cp.total_profit > (SELECT AVG(total_profit) FROM CustomerProfit)
), WarehouseStats AS (
    SELECT 
        w.w_warehouse_sk,
        COUNT(DISTINCT inv.inv_item_sk) AS unique_item_count,
        SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
    FROM warehouse w
    JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY w.w_warehouse_sk
), ItemPromotion AS (
    SELECT 
        i.i_item_id,
        COUNT(DISTINCT p.p_promo_sk) AS promotion_count,
        AVG(i.i_current_price) AS avg_price
    FROM item i
    LEFT JOIN promotion p ON i.i_item_sk = p.p_item_sk
    GROUP BY i.i_item_id
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    ws.unique_item_count,
    ws.total_qty_on_hand,
    ip.promotion_count,
    ip.avg_price
FROM HighValueCustomers hvc
LEFT JOIN WarehouseStats ws ON hvc.c_customer_sk = (SELECT MAX(c.c_customer_sk) FROM customer c)
LEFT JOIN ItemPromotion ip ON ip.i_item_id = (SELECT MIN(i.i_item_id) FROM item i WHERE i.i_current_price > 100)
WHERE hvc.total_profit IS NOT NULL
ORDER BY hvc.total_profit DESC, ip.promotion_count ASC;
