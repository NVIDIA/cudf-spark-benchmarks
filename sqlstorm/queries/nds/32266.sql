
WITH  Sales_CTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
Customer_Summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
Return_Statistics AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
)
SELECT 
    cs.c_customer_sk, 
    cs.c_first_name, 
    cs.c_last_name, 
    cs.cd_gender, 
    cs.cd_marital_status,
    cs.total_orders,
    cs.total_spent,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_returned, 0) AS total_returned,
    sc.total_sales
FROM 
    Customer_Summary cs
LEFT JOIN 
    Return_Statistics rs ON cs.c_customer_sk = rs.sr_customer_sk
LEFT JOIN 
    Sales_CTE sc ON cs.total_spent = sc.total_sales
WHERE 
    cs.total_spent > 100
ORDER BY 
    cs.total_spent DESC
LIMIT 10;
