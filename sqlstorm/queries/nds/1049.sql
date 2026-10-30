
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        COUNT(DISTINCT sr_ticket_number) AS returns_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
SalesData AS (
    SELECT 
        ws_ship_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales_amt,
        COUNT(DISTINCT ws_order_number) AS sales_count
    FROM 
        web_sales
    GROUP BY 
        ws_ship_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
ReturnSalesComparison AS (
    SELECT 
        cd.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.income_lower,
        cd.income_upper,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        COALESCE(sd.total_sales_amt, 0) AS total_sales_amt,
        CASE 
            WHEN COALESCE(cr.total_return_amt, 0) = 0 THEN NULL 
            ELSE (COALESCE(sd.total_sales_amt, 0) - COALESCE(cr.total_return_amt, 0)) / COALESCE(sd.total_sales_amt, 0) 
        END AS return_to_sales_ratio
    FROM 
        CustomerDemographics cd
    LEFT JOIN CustomerReturns cr ON cd.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN SalesData sd ON cd.c_customer_sk = sd.ws_ship_customer_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(DISTINCT cd.c_customer_sk) AS customer_count,
    AVG(rsc.return_to_sales_ratio) AS avg_return_to_sales_ratio,
    SUM(rsc.total_return_amt) AS total_return_amt,
    SUM(rsc.total_sales_amt) AS total_sales_amt,
    MAX(rsc.income_upper) AS max_income_upper,
    MIN(rsc.income_lower) AS min_income_lower
FROM 
    ReturnSalesComparison rsc
JOIN CustomerDemographics cd ON rsc.c_customer_sk = cd.c_customer_sk
GROUP BY 
    cd.cd_gender,
    cd.cd_marital_status
ORDER BY 
    customer_count DESC, 
    avg_return_to_sales_ratio DESC
LIMIT 10;
