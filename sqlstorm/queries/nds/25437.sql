
WITH address_data AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LOWER(ca_city) AS city,
        REPLACE(ca_zip, '-', '') AS zip_code
    FROM 
        customer_address
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
order_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        i.i_item_desc,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ws.ws_bill_customer_sk,
        ws.ws_warehouse_sk
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
),
warehouse_data AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        CONCAT(w.w_street_number, ' ', w.w_street_name) AS full_warehouse_address
    FROM 
        warehouse w
)
SELECT 
    ad.full_address,
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    od.ws_order_number,
    od.i_item_desc,
    od.ws_quantity,
    od.ws_sales_price,
    od.ws_net_profit,
    wd.full_warehouse_address
FROM 
    address_data ad
JOIN 
    customer_data cd ON ad.ca_address_sk = cd.c_customer_sk
JOIN 
    order_data od ON cd.c_customer_sk = od.ws_bill_customer_sk
JOIN 
    warehouse_data wd ON wd.w_warehouse_sk = od.ws_warehouse_sk
WHERE 
    ad.city LIKE '%city%'
    AND od.ws_net_profit > 0
ORDER BY 
    od.ws_sales_price DESC
LIMIT 100;
