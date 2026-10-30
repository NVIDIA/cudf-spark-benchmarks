
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(ss.ss_item_sk) AS total_purchases,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY SUM(ss.ss_net_profit) DESC) AS rank_per_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, 
        cd.cd_credit_rating, cd.cd_purchase_estimate, ca.ca_city, ca.ca_state
),
GenderIncomeStats AS (
    SELECT
        cd.cd_gender,
        ib.ib_income_band_sk,
        COUNT(distinct cs.cs_order_number) AS order_count,
        AVG(cs.cs_net_profit) AS avg_net_profit
    FROM 
        customer_demographics cd
    JOIN
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        catalog_sales cs ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        cd.cd_gender, ib.ib_income_band_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.total_profit,
    cs.total_purchases,
    gis.order_count,
    gis.avg_net_profit
FROM 
    CustomerStats cs
LEFT JOIN 
    GenderIncomeStats gis ON cs.cd_gender = gis.cd_gender 
                          AND cs.total_purchases > 5 
WHERE 
    cs.rank_per_state <= 10
ORDER BY 
    cs.total_profit DESC, cs.c_last_name ASC
LIMIT 50;
