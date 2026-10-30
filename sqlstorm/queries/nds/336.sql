
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ws.ws_net_profit, 0) + COALESCE(cs.cs_net_profit, 0) + COALESCE(ss.ss_net_profit, 0)) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c_customer_id, 
        total_profit,
        web_order_count,
        catalog_order_count,
        store_order_count,
        RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
    FROM 
        CustomerSales
)
SELECT 
    tc.c_customer_id,
    tc.total_profit,
    tc.web_order_count,
    tc.catalog_order_count,
    tc.store_order_count,
    CASE 
        WHEN tc.web_order_count > 0 AND tc.catalog_order_count > 0 THEN 'Active in both channels'
        WHEN tc.web_order_count > 0 THEN 'Web only'
        WHEN tc.catalog_order_count > 0 THEN 'Catalog only'
        ELSE 'No orders'
    END AS order_channel_status
FROM 
    TopCustomers tc
WHERE 
    tc.profit_rank <= 10
ORDER BY 
    tc.total_profit DESC;
