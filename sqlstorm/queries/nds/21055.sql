
WITH RankedReturns AS (
    SELECT
        COALESCE(SR.sr_customer_sk, WR.wr_returning_customer_sk) AS Customer_SK,
        COALESCE(WR.wr_returned_date_sk, SR.sr_returned_date_sk) AS Return_Date,
        CASE 
            WHEN SR.sr_item_sk IS NOT NULL THEN 'Store Return'
            ELSE 'Web Return'
        END AS Return_Type,
        COALESCE(SR.sr_return_quantity, WR.wr_return_quantity) AS Return_Quantity,
        COALESCE(SR.sr_return_amt, WR.wr_return_amt) AS Return_Amount,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(SR.sr_customer_sk, WR.wr_returning_customer_sk) ORDER BY COALESCE(SR.sr_returned_date_sk, WR.wr_returned_date_sk) DESC) AS Return_Rank
    FROM 
        store_returns SR
    FULL OUTER JOIN 
        web_returns WR ON SR.sr_item_sk = WR.wr_item_sk AND (SR.sr_returned_date_sk = WR.wr_returned_date_sk OR WR.wr_returned_time_sk IS NULL)
    WHERE 
        (SR.sr_return_quantity >= 1 OR WR.wr_return_quantity IS NOT NULL)
),
CustomerDemographics AS (
    SELECT 
        CD.cd_demo_sk, 
        CD.cd_gender, 
        CD.cd_marital_status, 
        CD.cd_education_status, 
        CD.cd_purchase_estimate,
        R.Return_Status
    FROM 
        customer_demographics CD
    LEFT JOIN (
        SELECT 
            Customer_SK,
            CASE 
                WHEN COUNT(Return_Date) > 2 THEN 'Frequent Returner'
                WHEN COUNT(Return_Date) BETWEEN 1 AND 2 THEN 'Occasional Returner'
                ELSE 'Rare Returner'
            END AS Return_Status
        FROM 
            RankedReturns
        GROUP BY 
            Customer_SK
    ) R ON CD.cd_demo_sk = R.Customer_SK
)
SELECT 
    C.c_customer_id,
    D.cd_gender,
    D.cd_marital_status,
    D.Return_Status,
    SUM(RR.Return_Quantity) AS Total_Returns,
    AVG(RR.Return_Amount) AS Average_Return_Amount,
    COUNT(RR.Return_Date) AS Return_Frequency
FROM 
    customer C
JOIN 
    RankedReturns RR ON C.c_customer_sk = RR.Customer_SK
JOIN 
    CustomerDemographics D ON C.c_current_cdemo_sk = D.cd_demo_sk
WHERE 
    (D.Return_Status IS NOT NULL OR RR.Return_Type IS NOT NULL)
    AND (D.cd_gender = 'F' OR D.cd_marital_status = 'M')
GROUP BY 
    C.c_customer_id, D.cd_gender, D.cd_marital_status, D.Return_Status
HAVING 
    SUM(RR.Return_Quantity) > 0
ORDER BY 
    Total_Returns DESC NULLS LAST;
