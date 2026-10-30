
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        cd.cd_credit_rating = 'Excellent'
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
    ORDER BY 
        total_net_profit DESC
),
top_customers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS rank
    FROM 
        ranked_customers
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_education_status,
    tc.total_net_profit,
    d.d_date AS sales_date,
    i.i_product_name,
    ss.ss_quantity,
    ss.ss_net_profit
FROM 
    top_customers tc
JOIN 
    store_sales ss ON tc.c_customer_sk = ss.ss_customer_sk
JOIN 
    item i ON ss.ss_item_sk = i.i_item_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_net_profit DESC, d.d_date DESC;
