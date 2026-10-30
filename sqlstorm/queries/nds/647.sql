
WITH CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate, 
        SUM(ss.ss_net_paid) AS total_spent
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
IncomeBand AS (
    SELECT 
        ib.ib_income_band_sk, 
        ib.ib_lower_bound, 
        ib.ib_upper_bound, 
        COUNT(hd.hd_demo_sk) AS num_customers
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
CustomerStatistics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        total_spent,
        CASE 
            WHEN total_spent IS NULL THEN 'No sales'
            WHEN total_spent < ib.ib_lower_bound THEN 'Below Income Band'
            WHEN total_spent > ib.ib_upper_bound THEN 'Above Income Band'
            ELSE 'Within Income Band'
        END AS spending_status
    FROM 
        CustomerDemographics cd
    LEFT JOIN 
        IncomeBand ib ON cd.cd_purchase_estimate BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
)
SELECT 
    cd.cd_gender, 
    cd.cd_marital_status, 
    COUNT(*) AS customer_count,
    AVG(total_spent) AS average_spent,
    MAX(total_spent) AS max_spent,
    spending_status
FROM 
    CustomerStatistics cd
GROUP BY 
    cd.cd_gender, 
    cd.cd_marital_status, 
    spending_status
ORDER BY 
    customer_count DESC;
