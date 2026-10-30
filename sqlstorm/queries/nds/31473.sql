
WITH  sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        hd.hd_income_band_sk,
        SUM(ss.ss_net_profit) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE 
        c.c_birth_year >= 1980
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, cd.cd_gender, hd.hd_income_band_sk
    HAVING 
        SUM(ss.ss_net_profit) IS NOT NULL AND 
        SUM(ss.ss_net_profit) > 1000
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        hd.hd_income_band_sk,
        SUM(ss.ss_net_profit) * 1.1 AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, cd.cd_gender, hd.hd_income_band_sk
)

SELECT 
    sh.c_customer_sk,
    sh.c_first_name,
    sh.c_last_name,
    sh.cd_gender,
    ib.ib_income_band_sk,
    COALESCE(sh.total_profit, 0) AS total_profit
FROM 
    sales_hierarchy sh
LEFT JOIN 
    income_band ib ON sh.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    ib.ib_lower_bound IS NOT NULL AND 
    (sh.total_profit > 500 OR sh.cd_gender = 'F')
ORDER BY 
    total_profit DESC;
