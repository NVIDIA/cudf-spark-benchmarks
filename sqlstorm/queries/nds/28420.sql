
WITH AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
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
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesDetails AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit,
        EXTRACT(MONTH FROM d.d_date) AS sale_month,
        EXTRACT(YEAR FROM d.d_date) AS sale_year
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.ws_item_sk, sale_month, sale_year
)
SELECT 
    cd.full_name,
    ca.full_address,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    ss.total_quantity_sold,
    ss.total_net_profit,
    CONCAT('Month: ', ss.sale_month, ', Year: ', ss.sale_year) AS sale_period
FROM 
    CustomerDetails cd
JOIN 
    AddressDetails ca ON cd.c_customer_sk = ca.ca_address_sk
JOIN 
    SalesDetails ss ON cd.c_customer_sk = ss.ws_item_sk
WHERE 
    cd.cd_gender = 'F'
    AND ss.total_quantity_sold > 100
ORDER BY 
    ss.total_net_profit DESC 
LIMIT 50;
