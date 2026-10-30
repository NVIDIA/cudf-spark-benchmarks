
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_profit) AS total_profit, 
        COUNT(ws_order_number) AS order_count,
        AVG(ws_net_paid_inc_tax) AS average_order_value
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                           AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_bill_customer_sk
), demographic_summary AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status
), combined_summary AS (
    SELECT 
        ds.ws_bill_customer_sk, 
        ds.total_profit, 
        ds.order_count, 
        ds.average_order_value,
        ds.total_profit / NULLIF(ds.order_count, 0) AS profit_per_order,
        ds.total_profit / NULLIF(dus.unique_customers, 0) AS profit_per_customer,
        dus.cd_gender,
        dus.cd_marital_status
    FROM 
        sales_summary ds
    LEFT JOIN 
        demographic_summary dus ON ds.ws_bill_customer_sk = dus.cd_demo_sk
)
SELECT 
    c.c_customer_id, 
    cs.total_profit, 
    cs.order_count, 
    cs.average_order_value, 
    cs.profit_per_order, 
    cs.profit_per_customer, 
    cs.cd_gender, 
    cs.cd_marital_status
FROM 
    combined_summary cs
JOIN 
    customer c ON cs.ws_bill_customer_sk = c.c_customer_sk
ORDER BY 
    cs.total_profit DESC
LIMIT 100;
