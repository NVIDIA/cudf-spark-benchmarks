
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        ca_street_number,
        ca_street_name,
        ca_city,
        ca_state,
        ca_country
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL AND ca_country = 'USA'
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
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
        ws.ws_bill_customer_sk
    FROM 
        web_sales ws
)
SELECT 
    ad.ca_street_number || ' ' || ad.ca_street_name AS FullAddress,
    cd.c_first_name,
    cd.c_last_name,
    cd.c_email_address,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(ws.ws_net_profit) AS TotalProfit
FROM 
    AddressDetails ad
JOIN 
    CustomerDetails cd ON cd.c_customer_sk = ad.ca_address_sk
JOIN 
    WebSalesDetails ws ON ws.ws_bill_customer_sk = cd.c_customer_sk
GROUP BY 
    ad.ca_street_number, ad.ca_street_name, cd.c_first_name, cd.c_last_name, cd.c_email_address, cd.cd_gender, cd.cd_marital_status
HAVING 
    SUM(ws.ws_net_profit) > 0
ORDER BY 
    TotalProfit DESC;
