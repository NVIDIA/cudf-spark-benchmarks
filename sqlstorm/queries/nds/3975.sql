
WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
top_items AS (
    SELECT 
        ss.ws_sold_date_sk,
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales
    FROM 
        sales_summary ss
    WHERE 
        ss.sales_rank <= 10
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ti.ws_sold_date_sk,
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_sales,
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    COALESCE(ci.cd_purchase_estimate, 0) AS purchase_estimate,
    CASE 
        WHEN ci.cd_credit_rating IS NULL THEN 'Unknown' 
        ELSE ci.cd_credit_rating 
    END AS credit_rating
FROM 
    top_items ti
LEFT JOIN 
    customer_info ci ON ci.gender_rank = 1
ORDER BY 
    ti.total_sales DESC, 
    ti.ws_sold_date_sk, 
    ti.ws_item_sk;
