
WITH Ranked_Customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
Recent_Sales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ws.ws_bill_customer_sk
),
High_Value_Customers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        r.total_sales,
        r.order_count 
    FROM 
        Ranked_Customers rc
    JOIN 
        Recent_Sales r ON rc.c_customer_sk = r.ws_bill_customer_sk
    WHERE 
        rc.rnk <= 10 AND 
        (rc.cd_marital_status = 'M' OR rc.cd_gender = 'F')
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(r.total_sales, 0) AS total_sales,
    COALESCE(r.order_count, 0) AS order_count,
    (CASE 
        WHEN COALESCE(r.total_sales, 0) > 5000 THEN 'High Value'
        WHEN COALESCE(r.total_sales, 0) BETWEEN 2000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END) AS customer_value_category
FROM 
    High_Value_Customers c
FULL OUTER JOIN 
    Recent_Sales r ON c.c_customer_sk = r.ws_bill_customer_sk
ORDER BY 
    customer_value_category DESC, total_sales DESC;
