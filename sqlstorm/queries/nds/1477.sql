
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighSpendingCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM CustomerSales cs
    WHERE cs.total_spent IS NOT NULL AND cs.total_spent > 1000
),
PromotedItems AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY ws.ws_item_sk
)
SELECT 
    h.c_first_name,
    h.c_last_name,
    h.total_spent,
    COALESCE(p.total_sold, 0) AS total_items_sold,
    COALESCE(p.total_revenue, 0) AS total_revenue_from_promotions
FROM HighSpendingCustomers h
LEFT JOIN PromotedItems p ON h.c_customer_sk = p.ws_item_sk
WHERE h.rank <= 10
ORDER BY h.total_spent DESC;
