
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_ship_date_sk) AS days_active
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_id
),
SalesInsights AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.total_orders,
        cs.days_active,
        CASE 
            WHEN cs.total_sales >= 1000 THEN 'High Value'
            WHEN cs.total_sales BETWEEN 500 AND 999 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_segment
    FROM 
        CustomerSales cs
),
MonthlySales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS monthly_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year,
        d.d_month_seq
),
PromotionalEffect AS (
    SELECT 
        p.p_promo_name,
        SUM(ws.ws_ext_sales_price) AS promo_sales
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_name
)
SELECT 
    si.customer_value_segment,
    SUM(si.total_sales) AS total_sales,
    AVG(si.total_orders) AS avg_orders,
    MAX(ms.monthly_sales) AS peak_monthly_sales,
    SUM(pe.promo_sales) AS total_promo_sales
FROM 
    SalesInsights si
LEFT JOIN 
    MonthlySales ms ON si.total_sales > 500
LEFT JOIN 
    PromotionalEffect pe ON 1=1
GROUP BY 
    si.customer_value_segment
ORDER BY 
    total_sales DESC;
