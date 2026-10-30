
WITH CustomerStats AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT c.c_customer_id) AS customers_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND cd.cd_gender IN ('F', 'M')
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
), StoreStats AS (
    SELECT 
        s.s_store_name, 
        SUM(ss.ss_quantity) AS total_sales_quantity, 
        SUM(ss.ss_net_profit) AS total_sales_net_profit
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    JOIN 
        date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
    GROUP BY 
        s.s_store_name
), PromotionImpact AS (
    SELECT 
        p.p_promo_name,
        SUM(ws.ws_net_profit) AS total_promo_net_profit
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        p.p_promo_name
)
SELECT 
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_education_status,
    cs.total_quantity AS customer_total_quantity,
    cs.total_net_profit AS customer_total_net_profit,
    cs.customers_count,
    ss.s_store_name,
    ss.total_sales_quantity,
    ss.total_sales_net_profit,
    pi.p_promo_name,
    pi.total_promo_net_profit
FROM 
    CustomerStats cs
JOIN 
    StoreStats ss ON cs.total_net_profit > ss.total_sales_net_profit
JOIN 
    PromotionImpact pi ON cs.total_net_profit > pi.total_promo_net_profit
ORDER BY 
    cs.cd_gender, ss.total_sales_net_profit DESC;
