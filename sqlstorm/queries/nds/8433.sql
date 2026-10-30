
WITH sales_summary AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_bill_cdemo_sk
),
customer_demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count
    FROM 
        customer_demographics
),
customer_data AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        cs.total_sales,
        cs.total_profit,
        cs.order_count,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count
    FROM 
        customer c
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        JOIN sales_summary cs ON c.c_current_cdemo_sk = cs.ws_bill_cdemo_sk
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cd.c_customer_id,
    cd.ca_city,
    cd.total_sales,
    cd.total_profit,
    cd.order_count,
    COUNT(wh.w_warehouse_id) AS warehouse_count,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
FROM 
    customer_data cd
    LEFT JOIN warehouse wh ON cd.ca_city = wh.w_city
GROUP BY 
    cd.c_customer_id, cd.ca_city, cd.total_sales, cd.total_profit, cd.order_count
ORDER BY 
    total_sales DESC
LIMIT 100;
