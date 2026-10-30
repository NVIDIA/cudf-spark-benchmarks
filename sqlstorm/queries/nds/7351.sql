WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451545 AND 2451545 + 30 
    GROUP BY 
        ws_bill_customer_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
profitable_customers AS (
    SELECT 
        ci.c_customer_sk, 
        ci.c_first_name, 
        ci.c_last_name, 
        ci.cd_gender, 
        ci.cd_marital_status, 
        ci.cd_purchase_estimate,
        ss.total_quantity, 
        ss.total_sales, 
        ss.total_profit
    FROM 
        sales_summary ss
    JOIN 
        customer_info ci ON ss.ws_bill_customer_sk = ci.c_customer_sk
    WHERE 
        ss.total_profit > 1000 
)
SELECT 
    pc.c_first_name, 
    pc.c_last_name, 
    pc.total_quantity, 
    pc.total_sales, 
    pc.total_profit, 
    CASE 
        WHEN pc.cd_gender = 'M' THEN 'Male'
        WHEN pc.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender_description,
    CASE 
        WHEN pc.cd_marital_status = 'M' THEN 'Married'
        WHEN pc.cd_marital_status = 'S' THEN 'Single'
        ELSE 'Other'
    END AS marital_status_description 
FROM 
    profitable_customers pc
ORDER BY 
    pc.total_profit DESC
LIMIT 10;