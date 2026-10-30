
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        ca_city,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_zip,
        ca_country
    FROM 
        customer_address
    WHERE 
        ca_state IN ('CA', 'TX', 'NY')
),
DemographicsInfo AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        CONCAT(cd_gender, ' - ', cd_marital_status, ' - ', cd_education_status) AS demographic_info
    FROM 
        customer_demographics
),
SalesInfo AS (
    SELECT 
        ws_item_sk,
        COUNT(ws_order_number) AS total_sales,
        SUM(ws_sales_price) AS total_revenue,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CombinedInfo AS (
    SELECT 
        a.ca_city,
        a.full_address,
        a.ca_zip,
        a.ca_country,
        d.cd_demo_sk,
        d.demographic_info,
        s.total_sales,
        s.total_revenue,
        s.total_profit
    FROM 
        AddressInfo a
    JOIN 
        customer c ON a.ca_address_sk = c.c_current_addr_sk
    JOIN 
        DemographicsInfo d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN 
        SalesInfo s ON c.c_customer_sk = s.ws_item_sk
)
SELECT 
    *,
    CASE 
        WHEN total_profit > 10000 THEN 'High'
        WHEN total_profit BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM 
    CombinedInfo
WHERE 
    ca_country = 'USA'
ORDER BY 
    total_revenue DESC, ca_city, demographic_info;
