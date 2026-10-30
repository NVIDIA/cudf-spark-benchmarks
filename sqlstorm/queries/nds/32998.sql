
WITH  customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_count,
        SUM(ss.ss_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
promotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        COUNT(ws.ws_order_number) AS promo_sales_count,
        SUM(ws.ws_net_profit) AS promo_total_profit
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk, p.p_promo_name
),
aggregate_sales AS (
    SELECT 
        ca.cd_gender,
        SUM(ca.total_profit) AS total_profit,
        COUNT(DISTINCT ca.c_customer_sk) AS unique_customers,
        SUM(ps.promo_total_profit) AS promotion_profit
    FROM 
        customer_analysis ca
    LEFT JOIN 
        promotions ps ON ps.promo_sales_count > 100
    GROUP BY 
        ca.cd_gender
)
SELECT 
    a.cd_gender,
    a.total_profit,
    a.unique_customers,
    COALESCE(a.promotion_profit, 0) AS promotion_profit,
    RANK() OVER (ORDER BY a.total_profit DESC) AS profit_rank
FROM 
    aggregate_sales a
WHERE 
    a.total_profit > (SELECT AVG(total_profit) FROM aggregate_sales)
ORDER BY 
    a.total_profit DESC;
