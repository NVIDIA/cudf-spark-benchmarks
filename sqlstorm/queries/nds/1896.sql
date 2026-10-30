
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 5000
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2457537 AND 2457547
    GROUP BY 
        ws_bill_customer_sk
),
returns_summary AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk BETWEEN 2457537 AND 2457547
    GROUP BY 
        wr_returning_customer_sk
)
SELECT
    rc.c_customer_sk,
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    ss.total_net_profit,
    rs.total_return_amount,
    COALESCE(ss.total_net_profit, 0) - COALESCE(rs.total_return_amount, 0) AS net_profit_after_returns
FROM 
    ranked_customers rc
LEFT JOIN 
    sales_summary ss ON rc.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN 
    returns_summary rs ON rc.c_customer_sk = rs.wr_returning_customer_sk
WHERE 
    rc.rank <= 10
ORDER BY 
    net_profit_after_returns DESC;
