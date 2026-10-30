
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(DISTINCT sr_ticket_number) AS total_return_count
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
                                 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics AS hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, hd.hd_buy_potential
),
RankedDemographics AS (
    SELECT 
        cd.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.buy_potential,
        cd.customer_count,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(cr.total_return_quantity) DESC) AS gender_rank
    FROM 
        CustomerDemographics AS cd
    LEFT JOIN 
        CustomerReturns AS cr ON cd.c_customer_sk = cr.sr_customer_sk
    GROUP BY 
        cd.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.buy_potential, cd.customer_count
)

SELECT 
    rd.cd_gender,
    rd.cd_marital_status,
    rd.cd_education_status,
    rd.buy_potential,
    rd.customer_count,
    COALESCE(MAX(rd.gender_rank), 0) AS rank,
    COUNT(CASE WHEN cr.total_return_count > 0 THEN 1 END) AS return_customers,
    AVG(COALESCE(cr.total_return_amt, 0)) AS avg_return_amt
FROM 
    RankedDemographics AS rd
LEFT JOIN 
    CustomerReturns AS cr ON rd.c_customer_sk = cr.sr_customer_sk
GROUP BY 
    rd.cd_gender, rd.cd_marital_status, rd.cd_education_status, rd.buy_potential, rd.customer_count
ORDER BY 
    rd.cd_gender, rd.cd_marital_status, rd.cd_education_status DESC;
