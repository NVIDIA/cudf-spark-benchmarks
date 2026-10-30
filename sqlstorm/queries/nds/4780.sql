
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
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
        cs.total_orders,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_spent IS NOT NULL
),
HighSpendingCustomers AS (
    SELECT 
        tc.c_customer_id, 
        tc.total_orders,
        tc.total_spent
    FROM 
        TopCustomers tc
    WHERE 
        tc.rank <= 10
),
SalesOverview AS (
    SELECT 
        SUM(ss.ss_net_paid) AS store_sales_total,
        SUM(ws.ws_net_paid) AS online_sales_total,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_online_sales
    FROM 
        store_sales ss
    FULL OUTER JOIN 
        web_sales ws ON ss.ss_item_sk = ws.ws_item_sk
)
SELECT 
    hsc.c_customer_id,
    hsc.total_orders,
    hsc.total_spent,
    so.store_sales_total,
    so.online_sales_total,
    so.total_store_sales,
    so.total_online_sales
FROM 
    HighSpendingCustomers hsc
CROSS JOIN 
    SalesOverview so
WHERE 
    hsc.total_spent > (SELECT AVG(total_spent) FROM CustomerSales)
ORDER BY 
    hsc.total_spent DESC;
