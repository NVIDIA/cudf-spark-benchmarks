WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2459903 AND 2459930  
    GROUP BY 
        ws_bill_customer_sk
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cs.total_sales,
        cs.order_count,
        cs.avg_net_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        sales_summary cs ON c.c_customer_sk = cs.ws_bill_customer_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    COALESCE(cd.total_sales, 0) AS total_sales,
    COALESCE(cd.order_count, 0) AS order_count,
    COALESCE(cd.avg_net_profit, 0) AS avg_net_profit,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
FROM 
    customer_details cd
JOIN 
    customer_address ca ON cd.c_customer_sk = ca.ca_address_sk
WHERE 
    cd.total_sales > 1000
ORDER BY 
    cd.avg_net_profit DESC
LIMIT 100;