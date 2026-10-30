
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2458937 AND 2458940 
    GROUP BY 
        ws_item_sk
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
item_data AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand
    FROM 
        item i
    WHERE 
        i.i_rec_start_date <= CURRENT_DATE AND 
        (i.i_rec_end_date IS NULL OR i.i_rec_end_date > CURRENT_DATE)
),
final_report AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_education_status,
        ss.total_quantity,
        ss.total_sales,
        ss.order_count,
        it.i_item_desc,
        it.i_current_price,
        it.i_brand
    FROM 
        customer_data cs
    JOIN 
        sales_summary ss ON cs.c_customer_sk = ss.ws_item_sk
    JOIN 
        item_data it ON ss.ws_item_sk = it.i_item_sk
)
SELECT 
    * 
FROM 
    final_report
ORDER BY 
    total_sales DESC
LIMIT 
    10;
