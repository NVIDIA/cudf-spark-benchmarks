
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk 
                                FROM date_dim 
                                WHERE d_year = 2023
                                  AND d_moy IN (5, 6) 
                                  AND d_dow NOT IN (1, 7))
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
PromotionSummary AS (
    SELECT 
        p.p_promo_id,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        p.p_promo_id
),
TopPromotions AS (
    SELECT 
        ps.p_promo_id,
        ps.total_profit,
        RANK() OVER (ORDER BY ps.total_profit DESC) AS profit_rank
    FROM 
        PromotionSummary ps
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_sales,
    tp.total_profit
FROM 
    CustomerSales cs
LEFT JOIN TopPromotions tp ON cs.total_sales > 10000
WHERE 
    tp.profit_rank <= 10
ORDER BY 
    cs.total_sales DESC
LIMIT 20;
