
WITH sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
), 
item_inventory AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
high_value_items AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        ii.total_inventory
    FROM 
        sales_data sd
    JOIN 
        item_inventory ii ON sd.ws_item_sk = ii.inv_item_sk
    WHERE 
        sd.sales_rank <= 10 
        AND sd.total_sales > 1000
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_first_name) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status IS NOT NULL
)
SELECT 
    hi.ws_item_sk,
    hi.total_quantity,
    hi.total_sales,
    hi.total_inventory,
    COUNT(DISTINCT ci.c_customer_sk) AS customer_count,
    MAX(ci.c_first_name || ' ' || ci.c_last_name) AS top_customer,
    SUM(CASE WHEN ci.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    SUM(CASE WHEN ci.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers
FROM 
    high_value_items hi
LEFT JOIN 
    customer_info ci ON hi.total_sales = ci.gender_rank
GROUP BY 
    hi.ws_item_sk, hi.total_quantity, hi.total_sales, hi.total_inventory
HAVING 
    hi.total_inventory > 50
ORDER BY 
    hi.total_sales DESC;
