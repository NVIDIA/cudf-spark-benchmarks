
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), 
CustomerDemographics AS (
    SELECT 
        cd_demo_sk, 
        MAX(cd_gender) AS gender, 
        MAX(cd_marital_status) AS marital_status, 
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer_demographics
    GROUP BY 
        cd_demo_sk
), 
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    cd.gender,
    cd.marital_status,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.total_orders, 0) AS total_orders,
    CASE 
        WHEN COALESCE(sd.total_sales, 0) = 0 THEN NULL 
        ELSE ROUND(COALESCE(cr.total_return_amount, 0) / COALESCE(sd.total_sales, 1) * 100, 2) 
    END AS return_rate_percentage
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
LEFT JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    ca.ca_state = 'CA'
ORDER BY 
    return_rate_percentage DESC
LIMIT 100;
