
WITH CustomerSales AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, SUM(ws.ws_ext_sales_price) AS total_sales
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT cs.c_customer_sk, cs.c_first_name, cs.c_last_name, cs.total_sales
    FROM CustomerSales cs
    JOIN customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'Good'
    ORDER BY cs.total_sales DESC
    LIMIT 10
),
PromotionStats AS (
    SELECT p.p_promo_sk, p.p_promo_name, COUNT(ws.ws_order_number) AS promotion_count, SUM(ws.ws_ext_sales_price) AS total_promo_sales
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY p.p_promo_sk, p.p_promo_name
)
SELECT 
    tc.c_first_name, 
    tc.c_last_name, 
    tc.total_sales, 
    ps.p_promo_name, 
    ps.total_promo_sales
FROM TopCustomers tc
LEFT JOIN PromotionStats ps ON tc.total_sales > ps.total_promo_sales
ORDER BY tc.total_sales DESC, ps.total_promo_sales DESC;
