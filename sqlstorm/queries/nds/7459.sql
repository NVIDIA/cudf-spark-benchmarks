
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales_count,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        SUM(ss.ss_quantity) AS total_quantity_sold
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 2459496 AND 2459796
    GROUP BY 
        c.c_customer_id
),
demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(*) AS demographic_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
average_income AS (
    SELECT 
        ib.ib_income_band_sk,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    d.cd_gender,
    d.cd_marital_status,
    ss.c_customer_id,
    ss.total_net_profit,
    ss.total_sales_count,
    ss.avg_sales_price,
    ss.total_quantity_sold,
    ai.avg_purchase_estimate
FROM 
    sales_summary ss
JOIN 
    demographics d ON ss.c_customer_id = d.cd_gender
LEFT JOIN 
    average_income ai ON d.demographic_count = ai.ib_income_band_sk
ORDER BY 
    ss.total_net_profit DESC
LIMIT 100;
