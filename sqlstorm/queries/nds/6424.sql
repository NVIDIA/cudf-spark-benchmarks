
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        ws.ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        cd.c_first_name,
        cd.c_last_name,
        sd.total_sales,
        sd.order_count,
        sd.unique_items
    FROM 
        customer_data cd
    JOIN 
        sales_data sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
    WHERE 
        sd.total_sales > 1000
    ORDER BY 
        sd.total_sales DESC
    LIMIT 10
)
SELECT 
    *,
    (CASE 
        WHEN unique_items > 5 THEN 'Diverse Purchaser' 
        ELSE 'Limited Purchaser' 
    END) AS purchase_behavior
FROM 
    top_customers;
