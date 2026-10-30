WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_ext_tax) AS total_tax
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2001
    GROUP BY 
        ws.ws_item_sk
),
item_data AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        i.i_category
    FROM 
        item i
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    id.i_item_desc,
    id.i_brand,
    id.i_category,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    SUM(sd.total_quantity) AS total_quantity,
    SUM(sd.total_sales) AS total_sales,
    SUM(sd.total_discount) AS total_discount,
    SUM(sd.total_tax) AS total_tax
FROM 
    sales_data sd
JOIN 
    item_data id ON sd.ws_item_sk = id.i_item_sk
JOIN 
    customer_data cd ON sd.ws_item_sk = cd.c_customer_sk  
GROUP BY 
    id.i_item_desc, id.i_brand, id.i_category, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
ORDER BY 
    total_sales DESC
LIMIT 100;