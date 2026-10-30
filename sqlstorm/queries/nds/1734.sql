
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_current_cdemo_sk, cd.cd_gender, cd.cd_marital_status
),
DateRange AS (
    SELECT 
        d.d_date_sk,
        d.d_year,
        d.d_month_seq
    FROM 
        date_dim d
    WHERE 
        d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
),
Promotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        SUM(ws.ws_net_paid) AS promo_sales
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE 
        p.p_start_date_sk >= (SELECT MAX(d.d_date_sk) FROM DateRange d)
    GROUP BY 
        p.p_promo_sk, p.p_promo_name
)
SELECT 
    cs.c_customer_sk,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_spent,
    cs.purchase_count,
    COALESCE(p.promo_sales, 0) AS total_promo_sales
FROM 
    CustomerStats cs
LEFT JOIN 
    Promotions p ON cs.c_current_cdemo_sk = p.p_promo_sk
WHERE 
    cs.total_spent > (SELECT AVG(total_spent) FROM CustomerStats)
ORDER BY 
    total_spent DESC
LIMIT 10;
