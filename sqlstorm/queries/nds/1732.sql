
WITH CustomerSales AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c_customer_sk, c_first_name, c_last_name
),
TopCustomers AS (
    SELECT 
        c_first_name,
        c_last_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_id,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        warehouse w
    JOIN 
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
SalesByDate AS (
    SELECT 
        ds.d_date,
        SUM(ws.ws_net_paid) AS total_revenue,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        date_dim ds
    LEFT JOIN 
        web_sales ws ON ds.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        ds.d_date
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    ws.total_inventory,
    sbd.total_revenue,
    sbd.total_orders
FROM 
    TopCustomers tc
LEFT JOIN 
    WarehouseStats ws ON ws.total_inventory > 100
JOIN 
    SalesByDate sbd ON sbd.total_revenue > 50000
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC, sbd.total_revenue DESC;
