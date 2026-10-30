
WITH Address_Processing AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        TRIM(UPPER(ca_city)) AS normalized_city,
        REGEXP_REPLACE(ca_zip, '[^0-9]', '') AS clean_zip
    FROM 
        customer_address
),
Sales_Analysis AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_paid) AS total_sales_amount
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        ws_item_sk
),
Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        a.full_address,
        a.normalized_city,
        a.clean_zip
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN 
        Address_Processing a ON c.c_current_addr_sk = a.ca_address_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.normalized_city,
    SUM(sa.total_quantity_sold) AS total_quantity_sold,
    SUM(sa.total_sales_amount) AS total_sales_amount,
    COUNT(DISTINCT sa.ws_item_sk) AS unique_items_bought
FROM 
    Customer_Info ci
LEFT JOIN 
    Sales_Analysis sa ON ci.c_customer_sk = sa.ws_item_sk
GROUP BY 
    ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.normalized_city
ORDER BY 
    total_sales_amount DESC
LIMIT 100;
