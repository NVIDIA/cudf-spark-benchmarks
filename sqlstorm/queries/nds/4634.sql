
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL 
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
), 
IncomeDistribution AS (
    SELECT 
        cd.cd_gender,
        CASE 
            WHEN cd.cd_purchase_estimate < 100 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 100 AND 500 THEN 'Medium'
            ELSE 'High'
        END AS income_category,
        COUNT(*) AS customer_count
    FROM 
        customer_demographics cd
    GROUP BY 
        cd.cd_gender, 
        CASE 
            WHEN cd.cd_purchase_estimate < 100 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 100 AND 500 THEN 'Medium'
            ELSE 'High'
        END
), 
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT
    ic.cd_gender,
    ic.income_category,
    SUM(tc.total_sales) AS total_sales_by_income,
    COUNT(tc.c_customer_id) AS number_of_customers
FROM 
    IncomeDistribution ic
JOIN 
    TopCustomers tc ON ic.customer_count > 0 
GROUP BY 
    ic.cd_gender, ic.income_category
ORDER BY 
    ic.cd_gender, total_sales_by_income DESC
LIMIT 10 OFFSET 5;
