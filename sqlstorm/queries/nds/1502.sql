
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_net_paid) AS total_sales
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 1 AND 365
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk AS customer_sk,
        cs.c_first_name AS first_name,
        cs.c_last_name AS last_name,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    tc.first_name,
    tc.last_name,
    CASE 
        WHEN tc.sales_rank <= 10 THEN 'TOP 10'
        ELSE 'OTHER'
    END AS customer_category,
    cs.total_sales,
    COALESCE((
        SELECT 
            AVG(total_sales) 
        FROM CustomerSales 
        WHERE total_sales < cs.total_sales
    ), 0) AS avg_sales_below
FROM 
    TopCustomers tc
LEFT JOIN 
    CustomerSales cs ON tc.customer_sk = cs.c_customer_sk
WHERE 
    cs.total_sales > 0
ORDER BY 
    cs.total_sales DESC;
