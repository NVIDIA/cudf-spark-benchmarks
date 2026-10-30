
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(d.d_date) AS last_purchase_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.order_count,
        cs.last_purchase_date
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.total_sales > 1000 AND cs.order_count > 5
),
SalesSummary AS (
    SELECT 
        hv.c_first_name,
        hv.c_last_name,
        hv.total_sales,
        hv.last_purchase_date,
        CASE 
            WHEN hv.total_sales > 5000 THEN 'VIP'
            WHEN hv.total_sales > 2000 THEN 'Gold'
            ELSE 'Silver'
        END AS customer_tier
    FROM 
        HighValueCustomers hv
)
SELECT 
    customer_tier,
    COUNT(*) AS customer_count,
    AVG(total_sales) AS average_sales,
    MIN(last_purchase_date) AS first_purchase,
    MAX(last_purchase_date) AS most_recent_purchase
FROM 
    SalesSummary
GROUP BY 
    customer_tier
ORDER BY 
    customer_tier DESC;
