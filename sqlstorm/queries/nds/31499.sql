
WITH  income_summary AS (
    SELECT 
        hd_demo_sk, 
        ib_income_band_sk, 
        SUM(hd_dep_count) AS total_dependent_count,
        COUNT(hd_demo_sk) AS household_count,
        MAX(hd_dep_count) AS max_dependent_count
    FROM 
        household_demographics 
    JOIN 
        income_band ON hd_income_band_sk = ib_income_band_sk
    GROUP BY 
        hd_demo_sk, ib_income_band_sk
), ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer AS c 
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        NULLIF(SUM(ws.ws_quantity), 0) AS quantity,
        SUM(ws.ws_net_paid_inc_tax) / NULLIF(SUM(ws.ws_quantity), 0) AS avg_net_paid_per_item
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
    GROUP BY 
        ws.ws_sold_date_sk
)
SELECT 
    ia.ib_income_band_sk,
    ia.total_dependent_count,
    ia.household_count,
    SUM(ss.total_profit) AS total_web_sales_profit,
    AVG(ss.avg_net_paid_per_item) AS avg_web_item_price,
    rc.c_first_name,
    rc.c_last_name,
    rc.gender_rank
FROM 
    income_summary AS ia
FULL OUTER JOIN 
    sales_summary AS ss ON ia.hd_demo_sk = ss.ws_sold_date_sk
JOIN 
    ranked_customers AS rc ON ia.hd_demo_sk = rc.c_customer_sk
GROUP BY 
    ia.ib_income_band_sk, 
    ia.total_dependent_count, 
    ia.household_count, 
    rc.c_first_name, 
    rc.c_last_name, 
    rc.gender_rank
HAVING 
    AVG(ss.avg_net_paid_per_item) IS NOT NULL
ORDER BY 
    ia.ib_income_band_sk, total_web_sales_profit DESC;
