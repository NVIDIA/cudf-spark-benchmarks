WITH CustomerData AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit
    FROM 
        web_sales ws
    WHERE
        ws.ws_sold_date_sk = (SELECT d.d_date_sk FROM date_dim d WHERE d.d_date = cast('2002-10-01' as date))
)
SELECT 
    COUNT(*) AS number_of_customers,
    SUM(sd.ws_quantity) AS total_quantity_sold,
    SUM(sd.ws_ext_sales_price) AS total_sales_value,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    COUNT(DISTINCT cd.cd_credit_rating) AS distinct_credit_ratings
FROM 
    CustomerData cd
LEFT JOIN 
    SalesData sd ON cd.full_name = CONCAT(sd.ws_order_number, ' Customer')  
GROUP BY 
    cd.cd_gender, 
    cd.cd_marital_status
ORDER BY 
    number_of_customers DESC