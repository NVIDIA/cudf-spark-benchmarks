
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        h.hd_income_band_sk,
        h.hd_buy_potential,
        COUNT(DISTINCT w.web_site_sk) AS website_count,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics h ON c.c_customer_sk = h.hd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        h.hd_income_band_sk,
        h.hd_buy_potential
),
AggregateData AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        h.hd_income_band_sk,
        COUNT(*) AS customer_count,
        AVG(ad.total_net_profit) AS avg_net_profit
    FROM CustomerData ad
    JOIN customer_demographics cd ON ad.c_customer_sk = cd.cd_demo_sk
    JOIN household_demographics h ON ad.c_customer_sk = h.hd_demo_sk
    GROUP BY 
        cd.cd_gender, 
        cd.cd_marital_status, 
        h.hd_income_band_sk
)
SELECT
    ad.cd_gender,
    ad.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ad.customer_count,
    ad.avg_net_profit
FROM AggregateData ad
JOIN income_band ib ON ad.hd_income_band_sk = ib.ib_income_band_sk
ORDER BY 
    ad.cd_gender,
    ad.cd_marital_status,
    ib.ib_lower_bound;
