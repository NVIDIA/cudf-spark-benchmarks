
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
Top10Cities AS (
    SELECT 
        ca_city, 
        COUNT(*) AS customer_count
    FROM 
        CustomerInfo
    GROUP BY 
        ca_city
    ORDER BY 
        customer_count DESC
    LIMIT 10
),
SalesData AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_ship_date_sk, 
        ws.ws_item_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    sd.total_quantity,
    sd.total_revenue
FROM 
    CustomerInfo ci
JOIN 
    SalesData sd ON ci.c_customer_sk = sd.ws_item_sk
WHERE 
    ci.ca_city IN (SELECT ca_city FROM Top10Cities)
ORDER BY 
    sd.total_revenue DESC
LIMIT 100;
