
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        ca.ca_city, 
        ca.ca_state, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ItemInfo AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_desc, 
        i.i_current_price,
        i.i_category
    FROM 
        item i
    WHERE 
        LOWER(i.i_item_desc) LIKE '%organic%'
),
SalesInfo AS (
    SELECT 
        ws.ws_order_number, 
        ws.ws_bill_customer_sk,
        ws.ws_quantity, 
        ws.ws_sales_price, 
        ws.ws_ship_date_sk
    FROM 
        web_sales ws
    JOIN 
        ItemInfo ii ON ws.ws_item_sk = ii.i_item_sk
),
Summary AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        SUM(si.ws_quantity) AS total_quantity,
        SUM(si.ws_sales_price) AS total_sales
    FROM 
        CustomerInfo ci
    JOIN 
        SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
    GROUP BY 
        ci.full_name, ci.ca_city, ci.ca_state
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    total_quantity,
    total_sales,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value Customer'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer' 
    END AS customer_category
FROM 
    Summary
ORDER BY 
    total_sales DESC;
