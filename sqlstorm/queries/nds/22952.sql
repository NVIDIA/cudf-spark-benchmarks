
WITH RevenueSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
), CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ib.ib_income_band_sk
    FROM 
        customer_demographics AS cd
    LEFT JOIN 
        household_demographics AS hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band AS ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        ib.ib_income_band_sk IS NOT NULL
), BestCustomers AS (
    SELECT 
        rs.c_customer_id,
        rs.total_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY rs.total_profit DESC) AS gender_rank
    FROM 
        RevenueSummary AS rs
    JOIN 
        customer AS c ON rs.c_customer_id = c.c_customer_id
    JOIN 
        CustomerDemographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FinalReport AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(bc.total_profit, 0) AS total_profit,
        CASE 
            WHEN bc.gender_rank IS NULL THEN 'Not Ranked'
            ELSE CONCAT('Rank ', bc.gender_rank)
        END AS rank_description
    FROM 
        customer AS c
    LEFT JOIN 
        BestCustomers AS bc ON c.c_customer_id = bc.c_customer_id
)
SELECT 
    fr.c_customer_id,
    fr.c_first_name,
    fr.c_last_name,
    fr.total_profit,
    fr.rank_description,
    CASE 
        WHEN fr.total_profit IS NULL THEN 'No Profit Recorded'
        WHEN fr.total_profit < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS profit_status,
    CONCAT('Customer: ', fr.c_first_name, ' ', fr.c_last_name, ' | Status: ', 
           CASE 
               WHEN fr.total_profit > 10000 THEN 'Gold'
               WHEN fr.total_profit > 5000 THEN 'Silver'
               ELSE 'Bronze'
           END) AS customer_status_summary
FROM 
    FinalReport AS fr
WHERE 
    fr.rank_description <> 'Not Ranked'
ORDER BY 
    fr.total_profit DESC;
