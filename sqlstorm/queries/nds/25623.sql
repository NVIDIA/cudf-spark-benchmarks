
WITH CustomerData AS (
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
ItemData AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_brand,
        i.i_category
    FROM 
        item i
    WHERE 
        i.i_current_price > 100.00
),
SalesData AS (
    SELECT 
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ws.ws_order_number,
        ws.ws_ship_date_sk,
        ci.c_customer_sk,
        ci.full_name,
        id.i_item_id,
        id.i_item_desc
    FROM 
        web_sales ws
    JOIN 
        CustomerData ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    JOIN 
        ItemData id ON ws.ws_item_sk = id.i_item_sk
),
Summary AS (
    SELECT 
        full_name,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_net_profit) AS average_profit
    FROM 
        SalesData
    GROUP BY 
        full_name
)
SELECT 
    sd.full_name,
    sd.total_orders,
    sd.total_quantity,
    sd.total_sales,
    sd.average_profit,
    CASE 
        WHEN sd.average_profit > 200 THEN 'High Profit'
        WHEN sd.average_profit BETWEEN 100 AND 200 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    Summary sd
ORDER BY 
    sd.total_sales DESC;
