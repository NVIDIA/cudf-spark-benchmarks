
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, hd.hd_income_band_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk AS customer_sk,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        c.total_sales,
        c.num_orders,
        DENSE_RANK() OVER (ORDER BY c.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales c
)
SELECT 
    tc.first_name,
    tc.last_name,
    tc.total_sales,
    tc.num_orders,
    CASE 
        WHEN tc.sales_rank <= 10 THEN 'Top 10% Customers'
        ELSE 'Other Customers'
    END AS customer_category
FROM 
    TopCustomers tc
WHERE 
    (tc.num_orders > 5 AND tc.total_sales > 500) OR tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC, tc.sales_rank ASC;
