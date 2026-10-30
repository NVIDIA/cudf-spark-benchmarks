
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate, 
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY cd.cd_purchase_estimate DESC) AS rank_summary
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(*) AS total_orders,
        SUM(ws_quantity) AS total_units_sold
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), 
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        ss.total_sales,
        ss.total_orders,
        ss.total_units_sold
    FROM 
        customer_summary cs
    JOIN 
        sales_summary ss ON cs.c_customer_sk = ss.ws_bill_customer_sk
    WHERE 
        cs.rank_summary <= 10
),

return_details AS (
    SELECT
        wr_returning_customer_sk,
        COUNT(*) AS total_returns,
        SUM(wr_return_amt) AS total_return_value
    FROM
        web_returns
    GROUP BY
        wr_returning_customer_sk
)

SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.total_orders,
    tc.total_units_sold,
    COALESCE(rd.total_returns, 0) AS total_returns,
    COALESCE(rd.total_return_value, 0) AS total_return_value,
    (tc.total_sales - COALESCE(rd.total_return_value, 0)) AS net_revenue
FROM 
    top_customers tc
LEFT JOIN 
    return_details rd ON tc.c_customer_sk = rd.wr_returning_customer_sk
ORDER BY 
    net_revenue DESC;
