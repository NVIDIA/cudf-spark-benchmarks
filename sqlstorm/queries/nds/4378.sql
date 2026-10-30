
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS spending_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_spent,
        cs.order_count
    FROM 
        CustomerSales cs
    WHERE 
        cs.spending_rank <= 10
),
SalesByWarehouse AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_net_paid) AS warehouse_sales_total
    FROM 
        web_sales ws 
    JOIN 
        inventory inv ON ws.ws_item_sk = inv.inv_item_sk
    JOIN 
        warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    tc.c_customer_id,
    tc.total_spent,
    tc.order_count,
    w.w_warehouse_id AS warehouse_id,
    w.warehouse_sales_total,
    CASE 
        WHEN tc.total_spent IS NULL THEN 'No Purchases'
        ELSE CASE 
            WHEN tc.total_spent > 1000 THEN 'High Value Customer'
            ELSE 'Regular Customer' 
        END 
    END AS customer_category
FROM 
    TopCustomers tc
FULL OUTER JOIN 
    SalesByWarehouse w ON w.warehouse_sales_total > 0
WHERE 
    w.w_warehouse_id IS NOT NULL 
    OR tc.total_spent IS NOT NULL
ORDER BY 
    tc.total_spent DESC NULLS LAST, 
    w.warehouse_sales_total DESC;
