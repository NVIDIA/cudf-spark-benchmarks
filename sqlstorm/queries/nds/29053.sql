
WITH AddressDetails AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
Demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    ad.customer_name,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    dm.cd_gender,
    dm.cd_marital_status,
    dm.cd_education_status,
    sd.total_quantity,
    sd.total_revenue
FROM 
    AddressDetails ad
JOIN 
    Demographics dm ON ad.customer_name LIKE CONCAT('%', dm.cd_gender, '%')
JOIN 
    SalesData sd ON sd.ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_item_desc LIKE '%widget%')
WHERE 
    ad.ca_state = 'CA' 
    AND dm.cd_marital_status = 'S'
GROUP BY 
    ad.customer_name,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    dm.cd_gender,
    dm.cd_marital_status,
    dm.cd_education_status,
    sd.total_quantity,
    sd.total_revenue
ORDER BY 
    sd.total_revenue DESC
LIMIT 10;
