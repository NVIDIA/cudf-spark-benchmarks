
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_state = 'NY'
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.ca_city,
        c.ca_state
    FROM 
        ranked_customers c
    WHERE 
        c.rank <= 10
),
sales_data AS (
    SELECT 
        ss.ss_customer_sk,
        SUM(ss.ss_net_profit) AS total_profit
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY 
        ss.ss_customer_sk
),
final_report AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.ca_city,
        tc.ca_state,
        COALESCE(sd.total_profit, 0) AS total_profit
    FROM 
        top_customers tc
    LEFT JOIN 
        sales_data sd ON tc.c_customer_sk = sd.ss_customer_sk
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.ca_city,
    f.ca_state,
    f.total_profit,
    CASE 
        WHEN f.total_profit = 0 THEN 'No Sales'
        WHEN f.total_profit < 1000 THEN 'Low Profit'
        WHEN f.total_profit < 5000 THEN 'Medium Profit'
        ELSE 'High Profit' 
    END AS profit_category
FROM 
    final_report f
ORDER BY 
    f.total_profit DESC;
