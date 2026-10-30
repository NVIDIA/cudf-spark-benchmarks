
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_first_shipto_date_sk IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_quantity,
        cs.total_spent,
        cs.avg_net_profit,
        RANK() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_spent DESC) AS rank_within_gender
    FROM CustomerSummary cs
),
HighSpenders AS (
    SELECT 
        tc.c_customer_id,
        tc.total_quantity,
        tc.total_spent,
        tc.rank_within_gender
    FROM TopCustomers tc
    WHERE tc.rank_within_gender <= 5
),
PromotionAnalysis AS (
    SELECT 
        p.p_promo_id,
        SUM(ws.ws_quantity) AS promo_quantity,
        SUM(ws.ws_net_paid) AS promo_total_spent
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.p_promo_id
)
SELECT 
    cs.c_customer_id,
    cs.total_quantity,
    cs.total_spent,
    hs.promo_quantity,
    hs.promo_total_spent
FROM HighSpenders cs
LEFT JOIN PromotionAnalysis hs ON cs.total_quantity = hs.promo_quantity
ORDER BY cs.total_spent DESC, cs.c_customer_id;
