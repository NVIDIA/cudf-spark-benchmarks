
WITH TotalSales AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_count,
        cd.cd_purchase_estimate,
        MAX(ws.ws_net_profit) AS max_profit,
        MIN(ws.ws_net_profit) AS min_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_dep_count, cd.cd_purchase_estimate
),
TopCustomers AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        cs.total_orders,
        cs.total_quantity,
        ROW_NUMBER() OVER (ORDER BY cs.total_orders DESC) AS rnk
    FROM 
        CustomerStats c
    JOIN 
        TotalSales cs ON c.c_customer_sk = cs.ws_sold_date_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_orders,
    tc.total_quantity,
    COALESCE(cs.total_profit, 0) AS total_profit,
    CASE 
        WHEN cs.total_profit > 0 THEN 'High Value'
        WHEN cs.total_profit = 0 THEN 'Neutral'
        ELSE 'Low Value' 
    END AS value_category
FROM 
    TopCustomers tc
LEFT JOIN 
    (SELECT 
        SUM(total_profit) AS total_profit, 
        SUM(total_orders) AS total_orders 
     FROM 
        TotalSales) cs 
ON 
    tc.rnk <= 10
WHERE 
    tc.total_quantity IS NOT NULL 
ORDER BY 
    tc.total_orders DESC;
