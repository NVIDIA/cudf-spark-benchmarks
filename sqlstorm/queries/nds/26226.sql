
WITH CustomerRanked AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
RecentReturns AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_quantity) AS total_returned,
        COUNT(*) AS return_count
    FROM 
        store_returns sr
    WHERE 
        sr.sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        sr.sr_customer_sk
),
MostActiveCustomers AS (
    SELECT 
        cr.sr_customer_sk,
        cr.total_returned,
        cr.return_count,
        cr.total_returned * 1.0 / NULLIF(cr.return_count, 0) AS average_return_quantity
    FROM 
        RecentReturns cr
    WHERE 
        cr.return_count > 5
)
SELECT 
    cr.full_name,
    cr.cd_gender,
    cr.cd_marital_status,
    mac.total_returned,
    mac.return_count,
    mac.average_return_quantity,
    CASE 
        WHEN cr.gender_rank <= 5 THEN 'Top Customer'
        ELSE 'Regular Customer' 
    END AS customer_status
FROM 
    CustomerRanked cr
JOIN 
    MostActiveCustomers mac ON cr.c_customer_sk = mac.sr_customer_sk
ORDER BY 
    mac.average_return_quantity DESC, cr.full_name;
