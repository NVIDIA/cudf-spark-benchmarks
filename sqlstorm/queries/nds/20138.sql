
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
Demographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        COALESCE(cd.cd_dep_count, 0) AS dep_count,
        COALESCE(cd.cd_dep_college_count, 0) AS dep_college_count,
        COALESCE(cd.cd_dep_employed_count, 0) AS dep_employed_count,
        CASE 
            WHEN cd.cd_marital_status IS NULL THEN 'Single'
            ELSE cd.cd_marital_status 
        END AS marital_status 
    FROM 
        customer c 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
SalesSummary AS (
    SELECT 
        ss_customer_sk AS customer_sk,
        SUM(ss_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ss_ticket_number) AS purchase_count
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_customer_sk
),
ReturnAnalysis AS (
    SELECT 
        d.c_customer_sk,
        d.cd_gender,
        d.hd_income_band_sk,
        d.hd_buy_potential,
        d.dep_count,
        d.dep_college_count,
        d.dep_employed_count,
        COALESCE(cr.total_returned_quantity, 0) AS total_returns,
        COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
        COALESCE(ss.total_spent, 0) AS total_spent,
        ss.purchase_count,
        CASE 
            WHEN COALESCE(cr.total_returned_amount, 0) / NULLIF(ss.total_spent, 0) > 0.5 THEN 'High Returner'
            ELSE 'Regular Customer' 
        END AS return_category
    FROM 
        Demographics d
    LEFT JOIN 
        CustomerReturns cr ON d.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        SalesSummary ss ON d.c_customer_sk = ss.customer_sk
)
SELECT 
    return_category,
    COUNT(*) AS num_customers,
    AVG(dep_count) AS avg_dependencies,
    AVG(total_spent) AS avg_spent,
    AVG(total_returns) AS avg_returns
FROM 
    ReturnAnalysis
GROUP BY 
    return_category
HAVING 
    AVG(total_spent) > 100 
    AND COUNT(*) > 10
ORDER BY 
    num_customers DESC;
