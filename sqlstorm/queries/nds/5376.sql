
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2458638 AND 2459304  
    GROUP BY 
        ws_bill_customer_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        d.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cs.total_quantity,
        cs.total_net_profit,
        cs.total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        sales_summary cs ON c.c_customer_sk = cs.ws_bill_customer_sk
    JOIN 
        date_dim d ON d.d_date_sk = cs.ws_bill_customer_sk
    WHERE 
        cd.cd_purchase_estimate > 1000  
),
ranked_customers AS (
    SELECT 
        *,
        DENSE_RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank
    FROM 
        customer_summary
)
SELECT 
    customer_name,
    total_quantity,
    total_net_profit,
    profit_rank,
    d_year
FROM 
    ranked_customers
WHERE 
    profit_rank <= 10  
ORDER BY 
    d_year, profit_rank;
