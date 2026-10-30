
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cp.total_quantity,
        cp.total_spent,
        cp.total_orders,
        RANK() OVER (ORDER BY cp.total_spent DESC) AS rank_spent,
        RANK() OVER (ORDER BY cp.total_quantity DESC) AS rank_quantity,
        RANK() OVER (ORDER BY cp.total_orders DESC) AS rank_orders
    FROM 
        CustomerPurchases cp
    JOIN 
        customer c ON c.c_customer_id = cp.c_customer_id
),
PromotionsUsed AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS promo_usage
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        p.p_promo_id
)
SELECT 
    tc.c_customer_id,
    tc.total_quantity,
    tc.total_spent,
    tc.total_orders,
    pu.promo_usage,
    CASE 
        WHEN tc.rank_spent <= 10 THEN 'Top 10 by Spending'
        ELSE 'Other'
    END AS customer_rank_category
FROM 
    TopCustomers tc
LEFT JOIN 
    PromotionsUsed pu ON pu.promo_usage > 0
WHERE 
    tc.rank_quantity <= 20 OR tc.rank_orders <= 20
ORDER BY 
    tc.total_spent DESC, tc.total_quantity DESC;
