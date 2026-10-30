
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales AS cs
    JOIN 
        customer AS c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_sales > 1000
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    p.p_promo_name,
    SUM(ws.ws_ext_discount_amt) AS total_discount
FROM 
    TopCustomers AS tc
LEFT JOIN 
    web_sales AS ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    promotion AS p ON ws.ws_promo_sk = p.p_promo_sk
JOIN 
    date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    tc.sales_rank <= 10
GROUP BY 
    tc.c_customer_sk, tc.c_first_name, tc.c_last_name, tc.total_sales, tc.order_count, p.p_promo_name
ORDER BY 
    tc.total_sales DESC;
