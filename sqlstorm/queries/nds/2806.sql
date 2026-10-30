
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ws.ws_net_paid_inc_tax, 0) + COALESCE(cs.cs_net_paid_inc_tax, 0) + COALESCE(ss.ss_net_paid_inc_tax, 0)) AS total_spent,
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
), RankCustomer AS (
    SELECT 
        cs.c_customer_id,
        cs.total_spent,
        cs.web_order_count,
        cs.catalog_order_count,
        cs.store_order_count,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spending_rank
    FROM 
        CustomerSales cs
)
SELECT 
    r.c_customer_id,
    r.total_spent,
    r.web_order_count,
    r.catalog_order_count,
    r.store_order_count,
    CASE 
        WHEN r.spending_rank <= 10 THEN 'Top 10%'
        WHEN r.spending_rank BETWEEN 11 AND 50 THEN 'Top 50%'
        ELSE 'Below 50%'
    END AS customer_spending_group
FROM 
    RankCustomer r
WHERE 
    (r.web_order_count > 0 OR r.catalog_order_count > 0 OR r.store_order_count > 0)
ORDER BY 
    r.spending_rank;
