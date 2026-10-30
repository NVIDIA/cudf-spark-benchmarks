WITH AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, 
               CASE WHEN ca.ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca.ca_suite_number) ELSE '' END) AS FullAddress,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer_address ca
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS CustomerFullName,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
WebSalesDetails AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_web_site_sk,
        wd.web_name
    FROM 
        web_sales ws
    JOIN 
        web_site wd ON ws.ws_web_site_sk = wd.web_site_sk
),
SalesSummary AS (
    SELECT 
        cs.cs_order_number,
        SUM(cs.cs_ext_sales_price) AS TotalSales,
        SUM(cs.cs_net_profit) AS TotalProfit
    FROM 
        catalog_sales cs
    GROUP BY 
        cs.cs_order_number
)
SELECT 
    cd.CustomerFullName,
    cd.c_email_address,
    ad.FullAddress,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    ad.ca_country,
    wsd.ws_sales_price,
    wsd.ws_quantity,
    wsd.ws_net_profit,
    ss.TotalSales,
    ss.TotalProfit
FROM 
    CustomerDetails cd
JOIN 
    AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
JOIN 
    WebSalesDetails wsd ON cd.c_customer_sk = wsd.ws_order_number  
LEFT JOIN 
    SalesSummary ss ON wsd.ws_order_number = ss.cs_order_number
WHERE 
    ad.ca_state = 'CA' AND
    cd.cd_gender = 'F' AND
    cd.cd_marital_status = 'M'
ORDER BY 
    TotalSales DESC
LIMIT 100;