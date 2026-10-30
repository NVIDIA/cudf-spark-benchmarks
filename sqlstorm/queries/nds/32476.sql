WITH  sales_data AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_item_sk) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1000 AND 2000
        AND ws_net_paid > 0
),
inventory_data AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
),
customer_data AS (
    SELECT 
        c_customer_sk,
        cd_marital_status,
        hd_income_band_sk,
        COUNT(DISTINCT cd_demo_sk) AS demographic_count
    FROM 
        customer
    LEFT JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    LEFT JOIN 
        household_demographics ON cd_demo_sk = hd_demo_sk
    GROUP BY 
        c_customer_sk, cd_marital_status, hd_income_band_sk
),
eligible_sales AS (
    SELECT 
        s.ws_order_number,
        s.ws_item_sk,
        s.ws_quantity,
        s.ws_sales_price,
        s.ws_net_paid,
        i.total_inventory,
        c.demographic_count
    FROM 
        sales_data s
    JOIN 
        inventory_data i ON s.ws_item_sk = i.inv_item_sk
    JOIN 
        customer_data c ON s.ws_order_number = c.c_customer_sk
    WHERE 
        i.total_inventory > 10 
        AND c.demographic_count > 0
)
SELECT 
    e.ws_order_number,
    e.ws_item_sk,
    SUM(e.ws_quantity) AS total_quantity,
    AVG(e.ws_sales_price) AS avg_sales_price,
    MAX(e.ws_net_paid) AS max_net_paid,
    COUNT(DISTINCT e.demographic_count) AS unique_demographics
FROM 
    eligible_sales e
GROUP BY 
    e.ws_order_number, e.ws_item_sk
HAVING 
    SUM(e.ws_quantity) > 5
ORDER BY 
    total_quantity DESC
LIMIT 100;