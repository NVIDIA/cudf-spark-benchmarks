
WITH DemographicDetails AS (
    SELECT 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status
),
AddressDetails AS (
    SELECT 
        ca.ca_state, 
        ca.ca_city, 
        COUNT(DISTINCT c.c_customer_id) AS customer_count_by_location
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_state, 
        ca.ca_city
),
SalesMetrics AS (
    SELECT
        ws.ws_sold_date_sk, 
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales_revenue,
        SUM(ws.ws_ext_tax) AS total_sales_tax
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk
)
SELECT 
    dd.cd_gender,
    dd.cd_marital_status,
    dd.cd_education_status,
    ad.ca_state,
    ad.ca_city,
    ad.customer_count_by_location,
    sm.total_orders,
    sm.total_sales_revenue,
    sm.total_sales_tax,
    dd.total_sales_quantity,
    dd.total_net_profit
FROM 
    DemographicDetails dd
JOIN 
    AddressDetails ad ON dd.customer_count = ad.customer_count_by_location
JOIN 
    SalesMetrics sm ON sm.total_orders = (SELECT MAX(total_orders) FROM SalesMetrics)
ORDER BY 
    dd.cd_gender, 
    ad.ca_state, 
    ad.ca_city;
