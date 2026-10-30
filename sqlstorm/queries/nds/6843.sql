
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2416 AND 2430  
    GROUP BY 
        ws_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ss.ss_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 2416 AND 2430  
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
inventory_summary AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    ss.ws_item_sk,
    cs.total_profit,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_education_status,
    ss.total_quantity,
    isq.total_inventory,
    ss.total_sales
FROM 
    sales_summary ss
JOIN 
    customer_summary cs ON ss.ws_item_sk = cs.c_customer_sk  
JOIN 
    inventory_summary isq ON ss.ws_item_sk = isq.inv_item_sk
ORDER BY 
    ss.total_sales DESC
LIMIT 100;
