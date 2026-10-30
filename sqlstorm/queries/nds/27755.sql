
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        ca_address_sk
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        c_customer_sk,
        c_current_cdemo_sk
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
OrderDetails AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        ws_bill_customer_sk,
        ws_ship_customer_sk
    FROM 
        web_sales
),
CombinedDetails AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        addr.full_address,
        addr.ca_city,
        addr.ca_state,
        addr.ca_zip,
        addr.ca_country,
        od.ws_order_number,
        od.ws_item_sk,
        od.ws_quantity,
        od.ws_sales_price,
        od.ws_net_profit
    FROM 
        CustomerDetails cd
    JOIN 
        AddressDetails addr ON cd.c_customer_sk = addr.ca_address_sk
    LEFT JOIN 
        OrderDetails od ON cd.c_customer_sk = od.ws_bill_customer_sk OR cd.c_customer_sk = od.ws_ship_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    ca_country,
    COUNT(ws_order_number) AS total_orders,
    SUM(ws_quantity) AS total_quantity,
    SUM(ws_sales_price) AS total_spent,
    AVG(ws_net_profit) AS avg_net_profit
FROM 
    CombinedDetails
WHERE 
    cd_marital_status = 'M' AND
    cd_purchase_estimate > 500
GROUP BY 
    full_name, cd_gender, cd_marital_status, cd_education_status, cd_purchase_estimate, 
    full_address, ca_city, ca_state, ca_zip, ca_country
ORDER BY 
    total_spent DESC
LIMIT 100;
