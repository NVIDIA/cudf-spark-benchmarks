
WITH  sales_analysis AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN
        (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 1 LIMIT 1) AND
        (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 12 LIMIT 1)
    GROUP BY 
        ws_item_sk
),
top_sales AS (
    SELECT 
        ws_item_sk,
        total_quantity,
        total_sales
    FROM 
        sales_analysis
    WHERE 
        rank <= 10
),
customer_info AS (
    SELECT 
        c_customer_sk,
        c_current_cdemo_sk,
        cd_gender,
        cd_marital_status,
        cd_credit_rating,
        cd_purchase_estimate
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
sales_details AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ci.c_customer_sk,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        ws.ws_sales_price,
        ws.ws_quantity,
        COALESCE(ws.ws_net_paid, 0) AS net_paid
    FROM 
        web_sales ws
    JOIN 
        customer_info ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    WHERE 
        ws.ws_item_sk IN (SELECT ws_item_sk FROM top_sales)
)
SELECT 
    sd.cd_gender,
    sd.cd_marital_status,
    COUNT(sd.ws_order_number) AS order_count,
    SUM(sd.ws_sales_price) AS total_sales_value,
    AVG(sd.ws_quantity) AS avg_quantity_per_order,
    SUM(sd.net_paid) AS total_net_paid
FROM 
    sales_details sd
GROUP BY 
    sd.cd_gender, 
    sd.cd_marital_status
ORDER BY 
    total_sales_value DESC
LIMIT 20;
