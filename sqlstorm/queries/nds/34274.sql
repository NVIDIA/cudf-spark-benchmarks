
WITH  CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS Total_Sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS Sales_Rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws.ws_ext_sales_price) > 1000
),
SalesWithReason AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.Total_Sales,
        COALESCE(
            (SELECT r.r_reason_desc 
             FROM reason r 
             JOIN web_returns wr ON r.r_reason_sk = wr.wr_reason_sk
             WHERE wr.wr_returning_customer_sk = cs.c_customer_sk
             LIMIT 1), 
            'No Returns') AS Return_Reason
    FROM 
        CustomerSales cs
)
SELECT 
    s.c_customer_sk,
    s.c_first_name,
    s.c_last_name,
    s.Total_Sales,
    s.Return_Reason,
    CASE 
        WHEN s.Total_Sales IS NULL THEN 'No Sales'
        WHEN s.Total_Sales > 5000 THEN 'High Value Customer'
        WHEN s.Return_Reason = 'No Returns' THEN 'Loyal Customer'
        ELSE 'Regular Customer'
    END AS Customer_Category
FROM 
    SalesWithReason s
LEFT JOIN 
    customer_demographics cd ON s.c_customer_sk = cd.cd_demo_sk
WHERE 
    cd.cd_gender = 'M' AND 
    (cd.cd_marital_status = 'M' OR cd.cd_dep_count > 2)
ORDER BY 
    s.Total_Sales DESC
LIMIT 10;
