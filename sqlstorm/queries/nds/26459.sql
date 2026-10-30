
WITH CustomerAddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_net_paid,
        ws.ws_sold_date_sk,
        d.d_date AS sale_date,
        d.d_month_seq,
        d.d_year
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
),
TotalSales AS (
    SELECT 
        cad.full_address,
        cad.ca_city,
        cad.ca_state,
        cad.ca_country,
        SUM(sd.ws_net_paid) AS total_sales,
        COUNT(sd.ws_order_number) AS order_count,
        EXTRACT(MONTH FROM sd.sale_date) AS sale_month,
        EXTRACT(YEAR FROM sd.sale_date) AS sale_year
    FROM 
        CustomerAddressDetails cad
    JOIN 
        SalesData sd ON cad.ca_city = 'San Francisco' AND cad.ca_state = 'CA'
    GROUP BY 
        cad.full_address, cad.ca_city, cad.ca_state, cad.ca_country, sale_month, sale_year
)
SELECT 
    full_address,
    ca_city,
    ca_state,
    ca_country,
    total_sales,
    order_count,
    ROW_NUMBER() OVER (PARTITION BY sale_month, sale_year ORDER BY total_sales DESC) AS rank
FROM 
    TotalSales
WHERE 
    total_sales > 1000
ORDER BY 
    sale_year DESC, sale_month DESC, total_sales DESC;
