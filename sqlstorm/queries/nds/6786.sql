
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate
), high_value_customers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        rc.cd_purchase_estimate,
        rc.total_spent
    FROM 
        ranked_customers rc
    WHERE 
        rc.rank <= 10
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.cd_education_status,
    hvc.cd_purchase_estimate,
    hvc.total_spent,
    d.d_date,
    SUM(ss.ss_quantity) AS total_purchases,
    SUM(ss.ss_net_profit) AS total_profit
FROM 
    high_value_customers hvc
JOIN 
    store_sales ss ON hvc.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
GROUP BY 
    hvc.c_customer_sk, hvc.c_first_name, hvc.c_last_name, hvc.cd_gender, hvc.cd_marital_status, hvc.cd_education_status, hvc.cd_purchase_estimate, hvc.total_spent, d.d_date
ORDER BY 
    total_spent DESC, total_profit DESC;
