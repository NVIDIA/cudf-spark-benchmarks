
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(COALESCE(sr_return_quantity, 0)) AS total_returns
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_purchase_estimate > (
            SELECT 
                AVG(cd2.cd_purchase_estimate) 
            FROM 
                customer_demographics cd2
        )
),
FrequentReturns AS (
    SELECT 
        cr.c_customer_sk,
        ROW_NUMBER() OVER (ORDER BY total_returns DESC) AS rn
    FROM 
        CustomerReturns cr
    WHERE 
        cr.total_returns > (
            SELECT 
                AVG(total_returns) 
            FROM 
                CustomerReturns
        )
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(wr.wr_item_sk) AS total_web_returns,
    SUM(wr.wr_return_amt) AS total_return_value
FROM 
    FrequentReturns fr
JOIN 
    customer c ON fr.c_customer_sk = c.c_customer_sk
JOIN 
    web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY 
    c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
HAVING 
    SUM(wr.wr_return_amt) > 100
ORDER BY 
    total_return_value DESC
LIMIT 10;
