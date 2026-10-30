
WITH CustomerOrders AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
), CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
), PromotionAnalytics AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS promo_orders,
        SUM(ws.ws_net_paid) AS promo_revenue
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.p_promo_id
), RankedCustomerOrders AS (
    SELECT 
        co.*,
        RANK() OVER (PARTITION BY co.total_orders ORDER BY co.total_spent DESC) AS order_rank
    FROM CustomerOrders co
)
SELECT 
    rco.c_customer_sk,
    rco.c_first_name,
    rco.c_last_name,
    rco.total_orders,
    rco.total_spent,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.income_band,
    pa.promo_orders,
    pa.promo_revenue
FROM RankedCustomerOrders rco
JOIN CustomerDemographics cd ON rco.c_customer_sk = cd.cd_demo_sk
FULL OUTER JOIN PromotionAnalytics pa ON rco.total_orders = pa.promo_orders
WHERE (rco.total_spent IS NULL OR rco.total_spent > (SELECT AVG(total_spent) FROM RankedCustomerOrders))
   AND cd.cd_gender = 'M'
   AND (pa.promo_revenue IS NULL OR pa.promo_revenue > 1000)
ORDER BY rco.total_spent DESC, rco.c_last_name ASC
LIMIT 10;
