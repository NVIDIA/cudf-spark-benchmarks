
WITH  Sales_CTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
Filtered_Sales AS (
    SELECT 
        s.ws_item_sk,
        s.total_quantity,
        s.total_profit
    FROM 
        Sales_CTE s
    WHERE 
        s.rank <= 5
),
Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        c.c_birth_year,
        d.cd_gender,
        d.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY d.cd_gender ORDER BY c.c_birth_year DESC) AS birth_rank
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
Top_Customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_birth_year,
        ci.cd_gender,
        ci.cd_marital_status
    FROM 
        Customer_Info ci
    WHERE 
        ci.birth_rank <= 10
),
Revenue_Report AS (
    SELECT 
        w.w_warehouse_name,
        SUM(f.total_profit) AS total_revenue
    FROM 
        Filtered_Sales f
    JOIN 
        inventory i ON f.ws_item_sk = i.inv_item_sk
    JOIN 
        warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_name
)
SELECT 
    r.w_warehouse_name,
    r.total_revenue,
    COALESCE(c.cd_gender, 'UNKNOWN') AS gender,
    COALESCE(c.cd_marital_status, 'UNKNOWN') AS marital_status
FROM 
    Revenue_Report r
LEFT JOIN 
    Top_Customers c ON r.total_revenue > 10000 AND c.c_customer_sk IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales) 
ORDER BY 
    r.total_revenue DESC,
    r.w_warehouse_name ASC;
