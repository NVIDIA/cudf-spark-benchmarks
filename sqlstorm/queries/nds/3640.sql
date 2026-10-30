
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        COUNT(ss.ss_item_sk) AS total_purchases,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_quantity) AS avg_quantity_per_purchase
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, hd.hd_income_band_sk
), 
purchase_rank AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.hd_income_band_sk,
        cs.total_purchases,
        cs.total_net_profit,
        cs.avg_quantity_per_purchase,
        RANK() OVER (ORDER BY cs.total_net_profit DESC) AS profit_rank
    FROM 
        customer_stats cs
),
potential_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        (CASE 
            WHEN cd.cd_marital_status IS NULL THEN 'Unknown'
            ELSE cd.cd_marital_status 
        END) AS marital_status,
        COALESCE(hd.hd_buy_potential, 'Low') AS buy_potential
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
)
SELECT 
    p.c_customer_sk,
    p.c_first_name,
    p.c_last_name,
    p.marital_status,
    p.buy_potential,
    pr.profit_rank,
    pr.total_purchases,
    pr.total_net_profit
FROM 
    potential_customers p
JOIN 
    purchase_rank pr ON p.c_customer_sk = pr.c_customer_sk
WHERE 
    pr.total_purchases > (
        SELECT AVG(total_purchases)
        FROM purchase_rank
    )
ORDER BY 
    pr.profit_rank 
LIMIT 20;
