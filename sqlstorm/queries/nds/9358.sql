
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        ws_ship_date_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws_item_sk) AS distinct_items_sold
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk BETWEEN 1000 AND 1100 
    GROUP BY 
        ws_bill_customer_sk, 
        ws_ship_date_sk
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
detailed_report AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.ca_city,
        cd.ca_state,
        ss.total_net_profit,
        ss.total_orders,
        ss.avg_sales_price,
        ss.distinct_items_sold
    FROM 
        customer_details cd
    LEFT JOIN 
        sales_summary ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    *,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM 
    detailed_report
WHERE 
    total_orders > 10
ORDER BY 
    profit_rank
LIMIT 100;
