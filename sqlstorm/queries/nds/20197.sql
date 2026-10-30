
WITH ranked_sales AS (
    SELECT 
        ws_ship_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_ship_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0 AND ws_net_paid > 0
    GROUP BY 
        ws_ship_customer_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        cd.cd_marital_status,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High Value'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value' 
        END AS customer_value,
        COALESCE(c.c_first_name || ' ' || c.c_last_name, 'Unnamed Customer') AS full_name
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
sales_summary AS (
    SELECT 
        ci.full_name,
        ci.customer_value,
        rs.total_profit,
        rs.order_count
    FROM 
        ranked_sales rs
    JOIN 
        customer_info ci ON rs.ws_ship_customer_sk = ci.c_customer_sk
)
SELECT 
    COALESCE(ss.full_name, 'Anonymous') AS customer_name,
    ss.customer_value,
    ss.total_profit,
    ss.order_count,
    CASE 
        WHEN ss.order_count IS NULL OR ss.total_profit IS NULL THEN 'No Data'
        ELSE 'Data Available'
    END AS data_status
FROM 
    sales_summary ss
FULL OUTER JOIN 
    (SELECT 
         NULL AS full_name, NULL AS customer_value, 
         NULL AS total_profit, NULL AS order_count 
     WHERE 
         (SELECT COUNT(*) 
          FROM web_sales 
          WHERE ws_net_profit IS NULL) > 0) AS dummy_data 
ON 
    ss.full_name = dummy_data.full_name
WHERE 
    (ss.order_count > 5 OR ss.customer_value = 'High Value')
ORDER BY 
    ss.total_profit DESC NULLS LAST
LIMIT 100;
