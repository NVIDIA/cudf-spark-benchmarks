
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ss.ss_net_paid) AS total_spent, 
        COUNT(ss.ss_item_sk) AS total_items,
        CD.cd_gender,
        HD.hd_income_band_sk
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        customer_demographics CD ON c.c_current_cdemo_sk = CD.cd_demo_sk
    LEFT JOIN 
        household_demographics HD ON c.c_current_hdemo_sk = HD.hd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, CD.cd_gender, HD.hd_income_band_sk
),
MonthlySales AS (
    SELECT 
        DATE_TRUNC('month', d.d_date) AS sales_month, 
        SUM(COALESCE(cs.total_spent, 0)) AS total_sales_amount,
        COUNT(cs.c_customer_sk) AS number_of_customers
    FROM 
        date_dim d
    LEFT JOIN 
        CustomerSales cs ON d.d_date_sk = cs.c_customer_sk
    GROUP BY 
        sales_month
)
SELECT 
    ms.sales_month, 
    ms.total_sales_amount, 
    ms.number_of_customers, 
    CASE 
        WHEN ms.total_sales_amount > 100000 THEN 'High Value Month'
        WHEN ms.total_sales_amount BETWEEN 50000 AND 100000 THEN 'Medium Value Month'
        ELSE 'Low Value Month' 
    END AS sales_category
FROM 
    MonthlySales ms
ORDER BY 
    ms.sales_month;
