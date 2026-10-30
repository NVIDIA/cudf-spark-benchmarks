
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
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
), ItemInfo AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        i.i_current_price,
        i.i_size,
        i.i_color,
        i.i_formulation
    FROM 
        item i
), SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
), CombinedData AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ii.i_product_name,
        ii.i_brand,
        ii.i_size,
        ii.i_color,
        sd.total_quantity,
        sd.total_profit,
        sd.total_orders,
        CASE 
            WHEN sd.total_profit > 1000 THEN 'High Profit'
            WHEN sd.total_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
            ELSE 'Low Profit'
        END AS profit_category
    FROM 
        CustomerInfo ci
    JOIN 
        SalesData sd ON ci.c_customer_sk = sd.ws_item_sk
    JOIN 
        ItemInfo ii ON sd.ws_item_sk = ii.i_item_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    profit_category,
    COUNT(*) AS customer_count,
    AVG(total_profit) AS avg_profit,
    SUM(total_quantity) AS total_items_sold
FROM 
    CombinedData ca
GROUP BY 
    ca.ca_city,
    ca.ca_state,
    profit_category
ORDER BY 
    ca.ca_city, ca.ca_state, customer_count DESC;
