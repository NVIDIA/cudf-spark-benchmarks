
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022
    GROUP BY 
        ws.ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL AND 
        cd.cd_marital_status = 'M'
),
inventory_levels AS (
    SELECT 
        i.i_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    JOIN 
        item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_sk
),
top_selling_items AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.order_count,
        c.c_first_name,
        c.c_last_name,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_purchase_estimate,
        il.total_inventory
    FROM 
        sales_data sd
    JOIN 
        customer_info c ON sd.ws_item_sk IN (
            SELECT 
                ws.ws_item_sk 
            FROM 
                web_sales ws 
            WHERE 
                ws.ws_ship_customer_sk IS NOT NULL
        )
    JOIN 
        inventory_levels il ON sd.ws_item_sk = il.i_item_sk
    WHERE 
        sd.sales_rank <= 10
)
SELECT 
    tsi.ws_item_sk,
    tsi.total_quantity,
    tsi.total_sales,
    tsi.order_count,
    tsi.c_first_name,
    tsi.c_last_name,
    tsi.cd_gender,
    tsi.cd_marital_status,
    tsi.cd_purchase_estimate,
    tsi.total_inventory,
    CASE 
        WHEN tsi.total_sales > 10000 THEN 'High Value'
        WHEN tsi.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS sales_value_category
FROM 
    top_selling_items tsi
ORDER BY 
    tsi.total_sales DESC;
