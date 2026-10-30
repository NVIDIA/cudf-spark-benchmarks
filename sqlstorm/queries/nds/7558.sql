
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_quantity) AS total_returned_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), 
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), 
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer_demographics
), 
DetailedReturns AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        cr.return_count,
        cr.total_returned_quantity,
        ss.total_sales,
        ss.total_discount,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        CustomerReturns cr
    JOIN 
        customer c ON cr.sr_customer_sk = c.c_customer_sk
    JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        SalesSummary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    cd_gender,
    cd_marital_status,
    COUNT(DISTINCT c_customer_id) AS customer_count,
    AVG(total_sales) AS avg_sales,
    SUM(total_returned_quantity) AS total_returns,
    SUM(total_discount) AS total_discounts
FROM 
    DetailedReturns
WHERE 
    return_count > 0
GROUP BY 
    cd_gender, cd_marital_status
ORDER BY 
    total_returns DESC, avg_sales DESC
LIMIT 10;
