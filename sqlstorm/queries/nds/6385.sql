
WITH sales_data AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
),
top_items AS (
    SELECT 
        ws_item_sk, 
        total_quantity,
        total_sales, 
        total_profit,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rank
    FROM 
        sales_data
),
customer_data AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name, 
        cd_gender, 
        cd_marital_status, 
        cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_analysis AS (
    SELECT 
        ci.ws_item_sk,
        ci.total_sales,
        ci.total_profit,
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        top_items ci
    JOIN 
        web_sales ws ON ci.ws_item_sk = ws.ws_item_sk
    JOIN 
        customer_data cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
    WHERE 
        ci.rank <= 10
)
SELECT 
    sa.c_customer_sk,
    sa.c_first_name,
    sa.c_last_name,
    sa.cd_gender,
    sa.cd_marital_status,
    SUM(sa.total_sales) AS total_sales_by_customer,
    SUM(sa.total_profit) AS total_profit_by_customer
FROM 
    sales_analysis sa
GROUP BY 
    sa.c_customer_sk, 
    sa.c_first_name, 
    sa.c_last_name, 
    sa.cd_gender, 
    sa.cd_marital_status
ORDER BY 
    total_sales_by_customer DESC;
