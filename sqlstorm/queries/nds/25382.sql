
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_customer_sk) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address
    FROM 
        customer_address ca
),
SalesDetails AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
AggregateSales AS (
    SELECT 
        item.i_item_id,
        COUNT(DISTINCT sd.ws_item_sk) AS total_web_items,
        SUM(sd.total_sales) AS aggregate_sales,
        SUM(sd.total_profit) AS aggregate_profit
    FROM 
        SalesDetails sd
    JOIN 
        item item ON sd.ws_item_sk = item.i_item_sk
    GROUP BY 
        item.i_item_id
)
SELECT 
    rc.full_name,
    rc.cd_gender,
    ad.full_address,
    agi.aggregate_sales,
    agi.aggregate_profit
FROM 
    RankedCustomers rc
JOIN 
    AddressDetails ad ON rc.c_customer_sk = ad.ca_address_sk
JOIN 
    AggregateSales agi ON agi.total_web_items > 10
WHERE 
    rc.gender_rank <= 100
ORDER BY 
    agi.aggregate_profit DESC
LIMIT 50;
