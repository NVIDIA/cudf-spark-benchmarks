
WITH  Sales_CTE AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders,
        RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
Customer_Stats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        COALESCE(s.total_net_profit, 0) AS total_net_profit,
        s.total_orders,
        CASE 
            WHEN COALESCE(s.total_net_profit, 0) > 10000 THEN 'High Value'
            WHEN COALESCE(s.total_net_profit, 0) BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        Sales_CTE s ON c.c_customer_sk = s.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND ca.ca_state IN ('CA', 'NY')
),
Top_Customers AS (
    SELECT 
        c.customer_value,
        COUNT(*) AS customer_count
    FROM 
        Customer_Stats c
    GROUP BY 
        c.customer_value
)
SELECT 
    customer_value,
    customer_count,
    (SELECT COUNT(*) FROM Customer_Stats) AS total_customers,
    ROUND((customer_count * 100.0 / (SELECT COUNT(*) FROM Customer_Stats)), 2) AS percentage_of_total
FROM 
    Top_Customers
ORDER BY 
    CASE customer_value 
        WHEN 'High Value' THEN 1 
        WHEN 'Medium Value' THEN 2 
        WHEN 'Low Value' THEN 3 
    END;
