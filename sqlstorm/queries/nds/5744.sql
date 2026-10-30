
WITH CTE_Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(d.d_date) AS last_purchase_date
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
CTE_Customer_Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
CTE_Combined AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        cs.last_purchase_date,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM 
        CTE_Customer_Sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    JOIN 
        CTE_Customer_Demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cb.c_customer_sk,
    cb.c_first_name,
    cb.c_last_name,
    cb.total_sales,
    cb.order_count,
    cb.last_purchase_date,
    cb.cd_gender,
    cb.cd_marital_status,
    cb.cd_credit_rating
FROM 
    CTE_Combined cb
WHERE 
    cb.total_sales > (SELECT AVG(total_sales) FROM CTE_Customer_Sales) 
    AND cb.cd_credit_rating = 'Low'
ORDER BY 
    cb.total_sales DESC
LIMIT 100;
