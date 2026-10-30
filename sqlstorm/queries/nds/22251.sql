
WITH  Sales_CTE AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS order_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), 
Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
Profitable_Customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.ca_city,
        sc.total_profit,
        sc.total_orders
    FROM 
        Customer_Info ci
    JOIN 
        Sales_CTE sc ON ci.c_customer_sk = sc.ws_bill_customer_sk
    WHERE 
        sc.total_profit IS NOT NULL AND 
        sc.total_orders > (SELECT AVG(total_orders) FROM Sales_CTE)
)

SELECT 
    pc.c_customer_sk,
    pc.c_first_name || ' ' || pc.c_last_name AS customer_name,
    pc.ca_city,
    pc.total_profit,
    pc.total_orders,
    DENSE_RANK() OVER (ORDER BY pc.total_profit DESC) AS profit_rank,
    CASE 
        WHEN pc.total_profit > 1000 THEN 'High Value'
        WHEN pc.total_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value,
    COALESCE((SELECT COUNT(*) FROM store_sales ss 
              WHERE ss.ss_customer_sk = pc.c_customer_sk AND 
                    ss.ss_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)), 0) AS store_sales_last_year,
    (SELECT 
        STRING_AGG(r.r_reason_desc, ', ') 
     FROM 
        store_returns sr 
     JOIN 
        reason r ON sr.sr_reason_sk = r.r_reason_sk 
     WHERE 
        sr.sr_customer_sk = pc.c_customer_sk) AS return_reasons
FROM 
    Profitable_Customers pc
WHERE 
    EXISTS (
        SELECT 1 
        FROM web_sales ws 
        WHERE ws.ws_bill_customer_sk = pc.c_customer_sk AND ws.ws_net_profit IS NOT NULL
    ) 
AND 
    NOT EXISTS (
        SELECT 1 
        FROM customer c 
        WHERE c.c_customer_sk = pc.c_customer_sk AND c.c_birth_year IS NULL
    )
ORDER BY 
    pc.total_profit DESC, 
    pc.c_customer_sk;
