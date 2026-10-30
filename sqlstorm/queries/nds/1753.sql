
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023 AND d_month_seq = 10
        )
    GROUP BY 
        sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        h.hd_income_band_sk
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics h ON c.c_customer_sk = h.hd_demo_sk
    WHERE 
        h.hd_income_band_sk IS NOT NULL
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023
        )
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    d.c_customer_sk,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    d.hd_income_band_sk,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_return_amt, 0) AS total_return_amt,
    COALESCE(s.total_net_profit, 0) AS total_net_profit,
    COALESCE(s.order_count, 0) AS order_count,
    COALESCE(s.avg_sales_price, 0) AS avg_sales_price
FROM 
    CustomerDemographics d
LEFT JOIN 
    CustomerReturns r ON d.c_customer_sk = r.sr_customer_sk
LEFT JOIN 
    SalesData s ON d.c_customer_sk = s.ws_bill_customer_sk
WHERE 
    (d.cd_gender = 'F' AND d.cd_marital_status IN ('M', 'S')) OR 
    (d.cd_gender = 'M' AND d.cd_marital_status = 'M')
ORDER BY 
    total_returns DESC, 
    total_net_profit DESC;
