
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ss.ss_net_paid, 0) + COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0)) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_purchases,
        COUNT(DISTINCT ws.ws_order_number) AS web_purchases
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
RankedCustomers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_spent DESC) AS sales_rank
    FROM 
        CustomerSales
)
SELECT 
    r.c_customer_id,
    r.c_first_name,
    r.c_last_name,
    r.total_spent,
    r.sales_rank,
    (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_customer_sk = c.c_customer_sk) AS total_returns,
    (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_returning_customer_sk = c.c_customer_sk) AS total_web_returns,
    CASE 
        WHEN r.total_spent > 1000 THEN 'High'
        WHEN r.total_spent BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS spending_category
FROM 
    RankedCustomers r
JOIN 
    customer c ON r.c_customer_id = c.c_customer_id
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.total_spent DESC;
