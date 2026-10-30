WITH AddressDetails AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
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
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
PopularItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        sd.total_quantity_sold,
        sd.total_net_profit,
        sd.order_count
    FROM 
        item i
    JOIN 
        SalesData sd ON i.i_item_sk = sd.ws_item_sk
    ORDER BY 
        sd.total_quantity_sold DESC
    LIMIT 10
)
SELECT 
    cd.full_name,
    ad.full_address,
    pi.i_item_desc,
    pi.total_quantity_sold,
    pi.total_net_profit,
    pi.order_count
FROM 
    CustomerDetails cd
JOIN 
    AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
JOIN 
    PopularItems pi ON cd.c_customer_sk IN (SELECT DISTINCT sr_customer_sk FROM store_returns) 
WHERE
    cd.cd_gender = 'M' AND
    ad.ca_state = 'CA'
ORDER BY 
    pi.total_net_profit DESC;