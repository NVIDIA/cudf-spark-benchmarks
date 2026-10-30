
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_sales_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
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
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
sales_analysis AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.ca_city,
        cd.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS purchase_category,
        RS.total_sales_profit
    FROM 
        customer_details cd
    JOIN 
        ranked_sales RS ON cd.c_customer_sk = RS.ws_bill_customer_sk
    WHERE 
        RS.rank <= 5
)
SELECT 
    s.*,
    RANK() OVER (PARTITION BY s.purchase_category ORDER BY s.total_sales_profit DESC) AS category_rank
FROM 
    sales_analysis s
WHERE 
    COALESCE(s.cd_gender, 'U') IN ('M', 'F', 'U')
    AND (s.ca_state IS NULL OR s.ca_state IN ('CA', 'TX', 'NY'))
    AND NOT EXISTS (
        SELECT 1 
        FROM store_returns sr 
        WHERE sr.sr_customer_sk = s.c_customer_sk
        HAVING SUM(sr.sr_return_quantity) > 5
    )
ORDER BY 
    s.purchase_category, 
    s.total_sales_profit DESC;
