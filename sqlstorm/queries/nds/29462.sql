
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
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
        i.i_product_name,
        i.i_current_price,
        i.i_wholesale_cost
    FROM 
        item i
    WHERE 
        i.i_item_desc LIKE '%premium%'
),
SalesInfo AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        ItemInfo ii ON ws.ws_item_sk = ii.i_item_sk
    GROUP BY 
        ws.ws_bill_customer_sk
),
CombinedInfo AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        si.total_sales,
        si.order_count,
        si.total_profit
    FROM 
        CustomerInfo ci
    JOIN 
        SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    total_sales,
    order_count,
    total_profit
FROM 
    CombinedInfo
WHERE 
    total_sales > 1000
ORDER BY 
    total_profit DESC
LIMIT 100;
