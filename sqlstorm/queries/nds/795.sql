
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1995
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cst.c_customer_sk,
        cst.c_first_name,
        cst.c_last_name,
        cst.total_sales,
        cst.order_count,
        RANK() OVER (ORDER BY cst.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cst
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    COALESCE(sms.sm_type, 'Unknown') AS shipping_method,
    CASE 
        WHEN tc.order_count > 5 THEN 'Frequent'
        WHEN tc.order_count BETWEEN 2 AND 5 THEN 'Moderate'
        ELSE 'Rare'
    END AS purchase_frequency,
    CASE 
        WHEN tc.total_sales > 10000 THEN 'High Value'
        ELSE 'Regular Value'
    END AS customer_value
FROM 
    TopCustomers tc
LEFT JOIN 
    (SELECT 
        ws.ws_ship_mode_sk, 
        sm.sm_type 
     FROM 
        web_sales ws
     JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk 
     GROUP BY 
        ws.ws_ship_mode_sk, sm.sm_type) AS sms 
ON 
    tc.c_customer_sk = sms.ws_ship_mode_sk
WHERE
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
