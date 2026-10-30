
WITH AddressComponents AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        dc.d_year,
        dc.d_month_seq,
        ac.full_address,
        ac.ca_city,
        ac.ca_state,
        ac.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressComponents ac ON c.c_current_addr_sk = ac.ca_address_sk
    JOIN 
        date_dim dc ON c.c_first_sales_date_sk = dc.d_date_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        cd.full_name,
        cd.ca_city,
        cd.ca_state
    FROM 
        web_sales ws
    JOIN 
        CustomerDetails cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
    GROUP BY 
        ws.ws_item_sk, cd.full_name, cd.ca_city, cd.ca_state
)
SELECT 
    sd.ws_item_sk,
    sd.total_quantity,
    sd.total_profit,
    COUNT(DISTINCT sd.full_name) AS unique_customers,
    COUNT(DISTINCT CONCAT(sd.ca_city, ', ', sd.ca_state)) AS unique_locations
FROM 
    SalesData sd
GROUP BY 
    sd.ws_item_sk, sd.total_quantity, sd.total_profit
HAVING 
    sd.total_profit > 1000
ORDER BY 
    sd.total_profit DESC;
