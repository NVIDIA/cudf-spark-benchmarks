
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_web_page_sk) AS distinct_web_pages
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
RecentOrders AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_spent,
        ROW_NUMBER() OVER (PARTITION BY cs.c_customer_sk ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_spent > 0
),
HighSpendingCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(avg(cd.cd_purchase_estimate), 0) AS avg_purchase_estimate,
        cs.total_spent,
        cs.order_count,
        cs.distinct_web_pages
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.c_customer_sk IN (SELECT c_customer_sk FROM RecentOrders WHERE rank <= 10)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cs.total_spent, cs.order_count, cs.distinct_web_pages
)
SELECT 
    DISTINCT h.c_first_name,
    h.c_last_name,
    h.total_spent,
    h.order_count,
    h.avg_purchase_estimate,
    h.distinct_web_pages,
    (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_returning_customer_sk = h.c_customer_sk) AS return_count,
    CASE 
        WHEN h.total_spent IS NULL THEN 'No Purchases'
        ELSE 'Active Customer'
    END AS status
FROM 
    HighSpendingCustomers h
LEFT JOIN 
    customer_address ca ON h.c_customer_sk = ca.ca_address_sk
WHERE 
    h.total_spent > (SELECT AVG(total_spent) FROM CustomerSales)
ORDER BY 
    h.total_spent DESC;
