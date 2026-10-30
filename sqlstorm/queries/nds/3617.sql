WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate > 1000
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim) - 30  
    GROUP BY 
        ws_bill_customer_sk
)

SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT r.sr_customer_sk) AS total_returns,
    SUM(CASE WHEN cd.cd_gender = 'F' THEN r.sr_return_quantity ELSE 0 END) AS female_return_quantity,
    SUM(CASE WHEN cd.cd_gender = 'M' THEN r.sr_return_quantity ELSE 0 END) AS male_return_quantity,
    SUM(ss.total_sales) AS web_sales_last_30_days
FROM 
    customer_address ca
LEFT JOIN 
    RankedReturns r ON r.sr_customer_sk = ca.ca_address_sk
LEFT JOIN 
    CustomerDemographics cd ON r.sr_customer_sk = cd.cd_demo_sk
LEFT JOIN 
    SalesSummary ss ON ss.ws_bill_customer_sk = ca.ca_address_sk
WHERE 
    ca.ca_state IN ('CA', 'NY') 
    AND cd.cd_marital_status = 'M'
GROUP BY 
    ca.ca_city,
    ca.ca_state
HAVING 
    COUNT(DISTINCT r.sr_customer_sk) > 10
ORDER BY 
    total_returns DESC, 
    ca.ca_city;