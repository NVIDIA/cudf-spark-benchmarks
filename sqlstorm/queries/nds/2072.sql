
WITH RankedReturns AS (
    SELECT 
        wr_returning_customer_sk,
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY wr_returning_customer_sk ORDER BY SUM(wr_return_amt) DESC) AS rn
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk, 
        wr_item_sk
),
HighValueReturns AS (
    SELECT 
        rr.wr_returning_customer_sk,
        rr.wr_item_sk,
        rr.total_returned,
        rr.total_return_amt,
        RANK() OVER (ORDER BY rr.total_return_amt DESC) AS return_rank
    FROM 
        RankedReturns rr
    WHERE 
        rr.total_returned > 5
),
CustomerDemographics AS (
    SELECT 
        cus.c_customer_sk,
        cus.c_first_name,
        cus.c_last_name,
        demo.cd_gender,
        demo.cd_marital_status,
        COALESCE(income.ib_lower_bound, 0) AS income_lower,
        COALESCE(income.ib_upper_bound, 0) AS income_upper
    FROM 
        customer cus
    LEFT JOIN 
        customer_demographics demo ON cus.c_current_cdemo_sk = demo.cd_demo_sk
    LEFT JOIN 
        household_demographics hhd ON hhd.hd_demo_sk = demo.cd_demo_sk
    LEFT JOIN 
        income_band income ON income.ib_income_band_sk = hhd.hd_income_band_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.income_lower,
    cd.income_upper,
    hvr.total_returned,
    hvr.total_return_amt
FROM 
    HighValueReturns hvr
JOIN 
    CustomerDemographics cd ON hvr.wr_returning_customer_sk = cd.c_customer_sk
WHERE 
    hvr.return_rank <= 10
ORDER BY 
    hvr.total_return_amt DESC;
