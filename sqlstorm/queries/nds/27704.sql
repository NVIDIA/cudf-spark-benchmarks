
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics AS hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        store_returns AS sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
),
formatted_data AS (
    SELECT 
        c_customer_id,
        full_name,
        cd_gender,
        cd_marital_status,
        income_band_sk,
        return_count,
        total_return_amount,
        CASE 
            WHEN return_count > 0 THEN 'Potential Loss'
            ELSE 'No Loss'
        END AS loss_status,
        CONCAT('Customer: ', full_name, 
               ' | Gender: ', cd_gender, 
               ' | Marital Status: ', cd_marital_status, 
               ' | Income Band: ', income_band_sk, 
               ' | Returns: ', return_count, 
               ' | Total Returns Amount: $', total_return_amount) AS customer_summary
    FROM 
        customer_data
)
SELECT 
    loss_status,
    COUNT(*) AS customer_count,
    SUM(return_count) AS total_returns,
    SUM(total_return_amount) AS overall_ret_amount,
    MAX(customer_summary) AS sample_customer_summary
FROM 
    formatted_data
GROUP BY 
    loss_status
ORDER BY 
    customer_count DESC;
