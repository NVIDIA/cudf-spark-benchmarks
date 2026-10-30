
WITH  CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),

CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band_sk,
        CA.ca_city,
        SUM(COALESCE(cr.total_returned, 0)) AS total_returned,
        SUM(COALESCE(cr.total_return_amount, 0)) AS total_return_amount
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN 
        customer_address CA ON c.c_current_addr_sk = CA.ca_address_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, 
        cd.cd_purchase_estimate, hd.hd_income_band_sk, CA.ca_city
),

SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)

SELECT 
    cd.c_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    CASE 
        WHEN sales.total_net_profit IS NULL THEN 'No Sales'
        ELSE 'Has Sales'
    END AS sales_status,
    COALESCE(income_band.ib_lower_bound, 0) AS lower_income_bound,
    COALESCE(income_band.ib_upper_bound, 1000000) AS upper_income_bound,
    cd.total_returned,
    cd.total_return_amount,
    sales.total_orders,
    sales.total_net_profit
FROM 
    CustomerDemographics cd
LEFT JOIN 
    SalesData sales ON cd.c_customer_sk = sales.ws_bill_customer_sk
LEFT JOIN 
    income_band ON cd.income_band_sk = income_band.ib_income_band_sk
WHERE 
    (cd.cd_gender = 'F' AND cd.total_returned > 5) OR 
    (cd.cd_marital_status = 'S' AND cd.total_return_amount > 500) OR 
    (cd.cd_purchase_estimate > 1000 AND sales.total_orders > 10)
ORDER BY 
    cd.cd_purchase_estimate DESC,
    cd.total_returned ASC;
