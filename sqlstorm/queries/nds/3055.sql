
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1980
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
),
PromotionData AS (
    SELECT 
        p.p_promo_id,
        SUM(cs.total_sales) AS promo_sales
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    JOIN 
        CustomerSales cs ON ws.ws_bill_customer_sk = cs.c_customer_sk
    GROUP BY 
        p.p_promo_id
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    COALESCE(pd.promo_sales, 0) AS promo_sales,
    CASE 
        WHEN tc.total_sales > 1000 THEN 'High Value'
        ELSE 'Regular'
    END AS customer_segment
FROM 
    TopCustomers tc
LEFT JOIN 
    PromotionData pd ON tc.sales_rank = 1
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
