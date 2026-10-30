
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesRank AS (
    SELECT 
        c.c_customer_sk AS customer_id,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        cs.total_web_sales,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
),

WarehouseStats AS (
    SELECT 
        w.w_warehouse_id,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        AVG(i.i_current_price) AS avg_item_price
    FROM 
        inventory inv
    JOIN 
        warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN 
        item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY 
        w.w_warehouse_id
)

SELECT 
    sr.customer_id,
    sr.first_name,
    sr.last_name,
    sr.total_web_sales,
    sr.total_orders,
    sr.sales_rank,
    ws.w_warehouse_id AS warehouse_id,
    ws.total_inventory,
    ws.avg_item_price
FROM 
    SalesRank sr
JOIN 
    WarehouseStats ws ON ws.total_inventory > 0
WHERE 
    sr.sales_rank <= 10
    AND sr.total_web_sales IS NOT NULL
ORDER BY 
    sr.sales_rank;
