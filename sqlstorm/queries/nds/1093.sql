
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS spend_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.order_count
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_credit_rating IS NOT NULL 
        AND cs.spend_rank <= 10
),
WarehousesStock AS (
    SELECT 
        i.i_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_stock
    FROM 
        inventory inv
    JOIN 
        item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_sk
)
SELECT 
    hvc.c_first_name, 
    hvc.c_last_name, 
    hvc.total_spent, 
    hvc.order_count, 
    ws.ws_sales_price,
    COALESCE(hvs.total_stock, 0) AS total_stock_available
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    web_sales ws ON hvc.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    WarehousesStock hvs ON ws.ws_item_sk = hvs.i_item_sk
WHERE 
    hvc.total_spent > (SELECT AVG(total_spent) FROM CustomerSales)
ORDER BY 
    hvc.total_spent DESC;
