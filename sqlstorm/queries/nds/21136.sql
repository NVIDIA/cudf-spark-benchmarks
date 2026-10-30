
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_amt) DESC) AS rnk
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
HighReturnCustomers AS (
    SELECT 
        CR.sr_customer_sk,
        CR.total_returned_quantity,
        CR.total_return_amt,
        C.c_first_name,
        C.c_last_name,
        CASE 
            WHEN C.c_birth_year IS NOT NULL THEN EXTRACT(YEAR FROM DATE '2002-10-01') - C.c_birth_year
            ELSE NULL 
        END AS customer_age
    FROM 
        RankedReturns CR
    JOIN 
        customer C ON CR.sr_customer_sk = C.c_customer_sk
    WHERE 
        CR.total_returned_quantity > (
            SELECT AVG(total_returned_quantity)
            FROM RankedReturns
        )
),
CustomerDemographics AS (
    SELECT 
        CD.cd_demo_sk,
        CD.cd_gender,
        HD.hd_income_band_sk
    FROM 
        customer_demographics CD
    LEFT JOIN 
        household_demographics HD ON CD.cd_demo_sk = HD.hd_demo_sk
),
OrdersSummary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        HRC.c_first_name,
        HRC.c_last_name,
        HRC.customer_age,
        CD.cd_gender,
        CD.hd_income_band_sk,
        COALESCE(OS.order_count, 0) AS order_count,
        COALESCE(OS.avg_net_profit, 0) AS avg_net_profit,
        HRC.total_returned_quantity,
        HRC.total_return_amt
    FROM 
        HighReturnCustomers HRC
    LEFT JOIN 
        CustomerDemographics CD ON HRC.sr_customer_sk = CD.cd_demo_sk
    LEFT JOIN 
        OrdersSummary OS ON HRC.sr_customer_sk = OS.customer_sk
)

SELECT 
    *
FROM 
    FinalReport
WHERE 
    (customer_age IS NULL OR customer_age > 30)
    AND 
    (total_return_amt > 100.00 OR (total_return_amt IS NULL AND total_returned_quantity > 5))
ORDER BY 
    total_return_amt DESC, order_count ASC;
