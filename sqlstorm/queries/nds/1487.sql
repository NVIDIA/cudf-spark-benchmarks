
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerIncome AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_demo_sk,
        hd.hd_income_band_sk,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential,
        CASE 
            WHEN hd.hd_dep_count IS NULL THEN 0
            ELSE hd.hd_dep_count
        END AS dep_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
ReturnAnalysis AS (
    SELECT 
        ci.c_customer_sk,
        ci.gender,
        ci.buy_potential,
        ci.dep_count,
        cr.return_count,
        cr.total_return_amount,
        cr.avg_return_quantity,
        RANK() OVER (PARTITION BY ci.buy_potential ORDER BY cr.total_return_amount DESC) AS rank_by_return
    FROM 
        CustomerIncome ci
    LEFT JOIN 
        CustomerReturns cr ON ci.c_customer_sk = cr.sr_customer_sk
)
SELECT 
    coalesce(buy_potential, 'Unspecified') AS income_category,
    COUNT(c_customer_sk) AS customer_count,
    SUM(total_return_amount) AS total_amount_returned,
    AVG(avg_return_quantity) AS average_quantity_returned
FROM 
    ReturnAnalysis
WHERE 
    rank_by_return <= 5
GROUP BY 
    income_category
ORDER BY 
    total_amount_returned DESC;
