
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        ap.full_address,
        ap.ca_city,
        ap.ca_state,
        ap.ca_zip,
        ap.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressParts ap ON c.c_current_addr_sk = ap.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_sales_price) AS max_sales_price,
        MIN(ws.ws_sales_price) AS min_sales_price
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
FinalReport AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        sd.total_sold,
        sd.total_profit,
        sd.order_count,
        sd.max_sales_price,
        sd.min_sales_price,
        CONCAT(cd.full_name, ' from ', cd.ca_city, ', ', cd.ca_state) AS customer_location
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        SalesData sd ON cd.c_customer_sk = sd.ws_item_sk
)
SELECT 
    customer_location,
    COUNT(*) AS customer_count,
    SUM(total_sold) AS total_units_sold,
    SUM(total_profit) AS total_revenue,
    AVG(cd_purchase_estimate) AS average_purchase_estimate
FROM 
    FinalReport
GROUP BY 
    customer_location
ORDER BY 
    total_revenue DESC
LIMIT 10;
