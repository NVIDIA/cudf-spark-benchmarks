
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_sales_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales_profit,
        cs.total_orders,
        cs.avg_order_value,
        RANK() OVER (ORDER BY cs.total_sales_profit DESC) AS profitability_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales_profit > 1000 AND cs.total_orders > 5
),
TopProducts AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_units_sold,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id
),
TopSalesByWarehouse AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_net_profit) AS warehouse_profit,
        COUNT(ws.ws_order_number) AS orders_fulfilled
    FROM 
        warehouse w
    JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    hvc.c_customer_id,
    hvc.total_sales_profit,
    hvc.total_orders,
    hvc.avg_order_value,
    tp.i_item_id,
    tp.total_units_sold,
    tp.total_profit,
    ts.w_warehouse_id,
    ts.warehouse_profit,
    ts.orders_fulfilled
FROM 
    HighValueCustomers hvc
JOIN 
    TopProducts tp ON hvc.total_sales_profit > 5000 
JOIN 
    TopSalesByWarehouse ts ON ts.warehouse_profit > 2000
ORDER BY 
    hvc.total_sales_profit DESC, tp.total_profit DESC;
