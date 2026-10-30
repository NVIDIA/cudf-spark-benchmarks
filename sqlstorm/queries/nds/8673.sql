
WITH sales_data AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_tax) AS total_tax,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS dd ON ws.ws_ship_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_ship_date_sk, ws.ws_item_sk
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_items AS (
    SELECT 
        item.i_item_id, 
        item.i_item_desc,
        sd.total_quantity,
        sd.total_sales,
        sd.total_profit,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        sales_data AS sd
    JOIN 
        item AS item ON sd.ws_item_sk = item.i_item_sk
)
SELECT 
    ci.c_customer_sk,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.cd_credit_rating,
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    ti.total_profit
FROM 
    customer_data AS ci
JOIN 
    top_items AS ti ON ti.sales_rank <= 10
ORDER BY 
    ci.c_customer_sk, ti.total_sales DESC;
