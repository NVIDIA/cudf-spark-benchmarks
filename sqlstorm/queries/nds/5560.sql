
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 2450000 AND 2450005 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.purchase_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cs.total_sales > 1000 
),
SalesStats AS (
    SELECT 
        p.p_promo_name,
        COUNT(DISTINCT hvc.c_customer_sk) AS customer_count,
        SUM(hvc.total_sales) AS total_sales_value
    FROM 
        HighValueCustomers hvc
    JOIN 
        promotion p ON hvc.total_sales >= p.p_cost
    GROUP BY 
        p.p_promo_name
)
SELECT 
    s.w_warehouse_name,
    ss.p_promo_name,
    ss.customer_count,
    ss.total_sales_value
FROM 
    SalesStats ss
JOIN 
    warehouse s ON ss.total_sales_value > s.w_warehouse_sq_ft
ORDER BY 
    ss.total_sales_value DESC;
