
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        MAX(ws_sold_date_sk) AS last_order_date
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY ws_bill_customer_sk
),

customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ci.total_orders,
        ci.total_sales,
        ci.total_profit,
        ci.last_order_date
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN sales_summary ci ON c.c_customer_sk = ci.ws_bill_customer_sk
    WHERE cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
),

profit_summary AS (
    SELECT 
        ci.ca_state,
        COUNT(ci.c_customer_sk) AS customer_count,
        SUM(ci.total_sales) AS total_sales,
        SUM(ci.total_profit) AS total_profit,
        AVG(ci.total_sales) AS avg_sales_per_customer,
        AVG(ci.total_profit) AS avg_profit_per_customer
    FROM customer_info ci
    GROUP BY ci.ca_state
)

SELECT 
    ps.ca_state,
    ps.customer_count,
    ps.total_sales,
    ps.total_profit,
    ps.avg_sales_per_customer,
    ps.avg_profit_per_customer,
    ROW_NUMBER() OVER (ORDER BY ps.total_profit DESC) AS state_rank
FROM profit_summary ps
WHERE ps.total_sales > 1000000
ORDER BY ps.total_profit DESC;
