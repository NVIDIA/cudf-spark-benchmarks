WITH  sales_volume AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders,
        RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 2451190 AND 2451210 
    GROUP BY 
        ws_bill_customer_sk
), 
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        sv.total_profit,
        sv.total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        sales_volume sv ON c.c_customer_sk = sv.ws_bill_customer_sk
    WHERE 
        sv.profit_rank <= 10
), 
customer_addresses AS (
    SELECT 
        c.c_customer_sk,
        MAX(ca.ca_city) AS city,
        MAX(ca.ca_state) AS state
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.cd_purchase_estimate,
    ca.city,
    ca.state,
    COALESCE(hvc.total_profit, 0) AS total_profit,
    COALESCE(hvc.total_orders, 0) AS total_orders,
    CASE 
        WHEN hvc.cd_marital_status = 'M' THEN 'Married'
        WHEN hvc.cd_marital_status = 'S' THEN 'Single'
        ELSE 'Other'
    END AS marital_status_desc
FROM 
    high_value_customers hvc
JOIN 
    customer_addresses ca ON hvc.c_customer_sk = ca.c_customer_sk
ORDER BY 
    hvc.total_profit DESC, hvc.c_last_name ASC;