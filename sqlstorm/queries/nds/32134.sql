
WITH  Sales_CTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) as rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
Top_Sales AS (
    SELECT 
        sc.ws_item_sk,
        sc.total_quantity,
        sc.total_profit
    FROM 
        Sales_CTE sc
    WHERE 
        sc.rn <= 10
),
Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) AS cust_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_credit_rating,
    ci.cd_purchase_estimate,
    ts.total_quantity,
    ts.total_profit,
    CASE 
        WHEN ci.cd_purchase_estimate > 10000 THEN 'High Value'
        WHEN ci.cd_purchase_estimate BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value_category
FROM 
    Top_Sales ts
JOIN 
    web_sales ws ON ts.ws_item_sk = ws.ws_item_sk
JOIN 
    Customer_Info ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
WHERE 
    ci.cust_rank = 1
    AND ci.cd_marital_status = 'M'
ORDER BY 
    ts.total_profit DESC;
