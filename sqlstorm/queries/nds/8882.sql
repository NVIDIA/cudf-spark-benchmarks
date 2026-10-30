
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_purchase_estimate, 
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), seasonal_sales AS (
    SELECT 
        dd.d_year, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        ws.ws_ship_mode_sk
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year IN (2022, 2023)
    GROUP BY 
        dd.d_year, ws.ws_ship_mode_sk
), top_items AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_desc, 
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc
    ORDER BY 
        total_quantity_sold DESC
    LIMIT 5
)
SELECT 
    rc.c_first_name, 
    rc.c_last_name, 
    rc.cd_gender, 
    rc.cd_marital_status, 
    ss.total_sales, 
    ss.total_quantity, 
    ti.i_item_desc
FROM 
    ranked_customers rc
JOIN 
    seasonal_sales ss ON rc.purchase_rank <= 5
JOIN 
    top_items ti ON ss.total_quantity > 10
ORDER BY 
    rc.cd_purchase_estimate DESC, ss.total_sales DESC;
