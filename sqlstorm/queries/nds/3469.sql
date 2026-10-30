
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS Total_Returns,
        SUM(sr_return_amt) AS Total_Return_Amount,
        AVG(sr_return_quantity) AS Avg_Return_Quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        cd.cd_dep_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
EnhancedReturns AS (
    SELECT 
        cr.sr_customer_sk,
        cr.Total_Returns,
        cr.Total_Return_Amount,
        cr.Avg_Return_Quantity,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        cd.cd_dep_count,
        CASE 
            WHEN cd.cd_purchase_estimate > 50000 THEN 'High Value'
            WHEN cd.cd_purchase_estimate BETWEEN 25000 AND 50000 THEN 'Mid Value'
            ELSE 'Low Value'
        END AS Customer_Value_Band
    FROM 
        CustomerReturns cr
    JOIN 
        CustomerDemographics cd ON cr.sr_customer_sk = cd.c_customer_sk
),
AggregateReturns AS (
    SELECT 
        Customer_Value_Band,
        COUNT(*) AS Number_of_Customers,
        SUM(Total_Returns) AS Total_Returns_Aggregated,
        SUM(Total_Return_Amount) AS Total_Return_Amount_Aggregated,
        AVG(Avg_Return_Quantity) AS Avg_Return_Quantity_Aggregated
    FROM 
        EnhancedReturns
    GROUP BY 
        Customer_Value_Band
)
SELECT 
    arb.Customer_Value_Band,
    arb.Number_of_Customers,
    arb.Total_Returns_Aggregated,
    arb.Total_Return_Amount_Aggregated,
    arb.Avg_Return_Quantity_Aggregated,
    COALESCE(ROUND((arb.Total_Return_Amount_Aggregated / NULLIF(arb.Total_Returns_Aggregated, 0)), 2), 0.00) AS Avg_Return_Amount_Per_Return
FROM 
    AggregateReturns arb
ORDER BY 
    Number_of_Customers DESC;
