
WITH CustomerReturns AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        cd_marital_status,
        cd_gender,
        COUNT(DISTINCT sr_item_sk) AS unique_items_returned
    FROM 
        customer AS c
    JOIN 
        store_returns AS sr ON c.c_customer_sk = sr.sr_customer_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        sr_returned_date_sk BETWEEN 20200601 AND 20201231
    GROUP BY 
        c.c_first_name, c.c_last_name, cd_marital_status, cd_gender
),
CustomerDemographics AS (
    SELECT
        cd_age_group,
        COUNT(*) AS customer_count
    FROM (
        SELECT 
            CASE 
                WHEN hd_income_band_sk IN (1, 2) THEN 'Low Income'
                WHEN hd_income_band_sk IN (3, 4) THEN 'Middle Income'
                ELSE 'High Income'
            END AS cd_age_group
        FROM 
            household_demographics
        WHERE 
            hd_demo_sk IN (SELECT DISTINCT c.c_current_hdemo_sk FROM customer AS c)
    ) AS demographic_data
    GROUP BY 
        cd_age_group
),
ReturnAnalysis AS (
    SELECT 
        cr.c_first_name,
        cr.c_last_name,
        cr.total_returned,
        cr.total_return_amount,
        cd.cd_age_group
    FROM 
        CustomerReturns AS cr
    JOIN 
        CustomerDemographics AS cd ON cr.return_count > 2
    ORDER BY 
        cr.total_return_amount DESC
)
SELECT 
    ra.c_first_name,
    ra.c_last_name,
    ra.total_returned,
    ra.total_return_amount,
    ra.cd_age_group
FROM 
    ReturnAnalysis AS ra
WHERE 
    ra.total_return_amount > 1000
ORDER BY 
    ra.total_returned DESC
LIMIT 50;
