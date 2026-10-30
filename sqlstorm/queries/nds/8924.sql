
WITH customer_returns AS (
    SELECT 
        wr_returning_customer_sk AS customer_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
demographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
returns_summary AS (
    SELECT 
        d.c_customer_sk AS customer_sk,
        d.c_first_name,
        d.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate,
        d.cd_credit_rating,
        d.cd_dep_count,
        COALESCE(c.total_returned, 0) AS total_returned,
        COALESCE(c.total_returned_amount, 0) AS total_returned_amount
    FROM 
        demographics d
    LEFT JOIN 
        customer_returns c ON d.c_customer_sk = c.customer_sk
)
SELECT 
    rs.*,
    CASE 
        WHEN rs.total_returned > 10 THEN 'High Returner'
        WHEN rs.total_returned > 0 THEN 'Low Returner'
        ELSE 'No Returner'
    END AS return_category
FROM 
    returns_summary rs
WHERE 
    rs.cd_gender = 'F' 
    AND rs.cd_marital_status = 'S' 
    AND rs.total_returned_amount > 100
ORDER BY 
    rs.total_returned_amount DESC
LIMIT 100;
