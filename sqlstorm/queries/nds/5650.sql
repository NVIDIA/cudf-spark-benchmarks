
WITH summarized_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 1000
    GROUP BY 
        ws_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M' AND 
        hd.hd_income_band_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, hd.hd_income_band_sk
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price
    FROM 
        item i 
    JOIN 
        summarized_sales ss ON i.i_item_sk = ss.ws_item_sk
    WHERE 
        ss.total_quantity_sold > 100
)
SELECT 
    cs.c_customer_sk,
    cs.cd_gender,
    cs.total_orders,
    id.i_item_id,
    id.i_product_name,
    id.i_current_price,
    ss.total_sales,
    ss.total_discount
FROM 
    customer_summary cs
JOIN 
    item_details id ON cs.c_customer_sk = id.i_item_sk
JOIN 
    summarized_sales ss ON id.i_item_sk = ss.ws_item_sk
ORDER BY 
    cs.total_orders DESC, ss.total_sales DESC
LIMIT 50;
