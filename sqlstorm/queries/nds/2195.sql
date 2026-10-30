
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank_spending
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id AS CustomerID,
        cs.total_spent,
        cs.total_orders,
        cs.rank_spending
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.rank_spending <= 10
)
SELECT 
    tc.CustomerID,
    tc.total_spent,
    tc.total_orders,
    COALESCE(p.p_promo_name, 'No Promotion') AS promotional_offer
FROM 
    TopCustomers tc
LEFT JOIN 
    promotion p ON tc.total_spent BETWEEN p.p_cost AND p.p_cost + 100
ORDER BY 
    tc.total_spent DESC;
