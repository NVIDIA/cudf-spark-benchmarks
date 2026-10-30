
WITH  sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_profit) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
    HAVING 
        SUM(ws_net_profit) > 10000
), 
returns_data AS (
    SELECT 
        cr_item_sk,
        COUNT(*) AS total_returns,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk
)
SELECT 
    cust.c_first_name,
    cust.c_last_name,
    cust.cd_gender,
    cust.order_count,
    cust.total_spent,
    COALESCE(SUM(r.total_returns), 0) AS total_returned_items,
    COALESCE(SUM(r.total_return_amount), 0) AS total_returned_amount,
    ss.total_sales_quantity,
    ss.total_net_profit
FROM 
    customer_info cust
LEFT JOIN 
    returns_data r ON cust.c_customer_sk = r.cr_item_sk
LEFT JOIN 
    sales_summary ss ON ss.ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
GROUP BY 
    cust.c_first_name, 
    cust.c_last_name,
    cust.cd_gender, 
    cust.order_count, 
    cust.total_spent,
    ss.total_sales_quantity,
    ss.total_net_profit
ORDER BY 
    cust.total_spent DESC
LIMIT 10;
