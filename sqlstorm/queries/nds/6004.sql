WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2459580 AND 2459880 
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
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)

SELECT 
    cd.c_first_name,
    cd.c_last_name,
    ss.total_sales,
    ss.total_profit,
    ss.total_orders,
    RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
FROM 
    sales_summary ss
JOIN 
    customer_details cd ON ss.ws_bill_customer_sk = cd.c_customer_sk
WHERE 
    ss.total_sales > 1000 
ORDER BY 
    ss.total_sales DESC
LIMIT 10;