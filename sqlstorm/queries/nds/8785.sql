
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year = 2023 AND 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M'
    GROUP BY 
        ws.ws_sold_date_sk
),
inventory_data AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
sales_inventory AS (
    SELECT 
        sd.ws_sold_date_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.order_count,
        id.total_inventory
    FROM 
        sales_data sd
    LEFT JOIN 
        inventory_data id ON sd.ws_sold_date_sk = id.inv_item_sk
)

SELECT 
    d.d_date AS sale_date,
    si.total_quantity,
    si.total_sales,
    si.order_count,
    si.total_inventory,
    CASE 
        WHEN si.total_quantity > 0 THEN 
            ROUND((si.total_sales / si.total_quantity), 2) 
        ELSE 0 END AS average_sale_price
FROM 
    sales_inventory si
JOIN 
    date_dim d ON si.ws_sold_date_sk = d.d_date_sk
ORDER BY 
    d.d_date;
