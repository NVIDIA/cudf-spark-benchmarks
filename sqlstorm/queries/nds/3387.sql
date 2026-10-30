
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state,
        CASE 
            WHEN cd.cd_purchase_estimate > 10000 THEN 'High Value'
            WHEN cd.cd_purchase_estimate BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_category
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_net_profit) AS average_profit
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
), 
return_summary AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(wr_order_number) AS return_count,
        SUM(wr_net_loss) AS total_return_loss
    FROM 
        web_returns 
    GROUP BY 
        wr_returning_customer_sk
), 
combined_summary AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        ss.total_sales,
        ss.order_count,
        rs.return_count,
        rs.total_return_loss,
        cs.customer_value_category
    FROM 
        customer_summary AS cs
    LEFT JOIN 
        sales_summary AS ss ON cs.c_customer_sk = ss.ws_bill_customer_sk
    LEFT JOIN 
        return_summary AS rs ON cs.c_customer_sk = rs.wr_returning_customer_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.total_sales,
    cs.order_count,
    COALESCE(cs.return_count, 0) AS return_count,
    COALESCE(cs.total_return_loss, 0) AS total_return_loss,
    ROW_NUMBER() OVER (PARTITION BY cs.customer_value_category ORDER BY cs.total_sales DESC) AS rank_within_category
FROM 
    combined_summary AS cs
WHERE 
    cs.total_sales IS NOT NULL
ORDER BY 
    cs.customer_value_category, 
    cs.total_sales DESC
LIMIT 100;
