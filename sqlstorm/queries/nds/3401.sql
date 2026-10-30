
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
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > (
            SELECT 
                AVG(total_sales) 
            FROM 
                CustomerSales
        )
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_sales,
    COALESCE(sms.sm_type, 'N/A') AS preferred_shipping_method,
    CASE 
        WHEN hvc.order_count > 5 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer'
    END AS buyer_category
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    (SELECT 
        ws.ws_bill_customer_sk, 
        sm.sm_type,
        COUNT(DISTINCT ws.ws_ship_mode_sk) AS mode_count
     FROM 
        web_sales ws
     JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
     GROUP BY 
        ws.ws_bill_customer_sk, sm.sm_type
    ) sms ON hvc.c_customer_sk = sms.ws_bill_customer_sk
WHERE 
    hvc.sales_rank <= 10
ORDER BY 
    hvc.total_sales DESC;
