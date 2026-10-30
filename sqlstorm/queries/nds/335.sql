
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(wb.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT wb.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(wb.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales wb ON c.c_customer_sk = wb.ws_bill_customer_sk
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
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_density
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > 1000
),
HighIncomeDemographics AS (
    SELECT 
        hd.hd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        household_demographics hd
    JOIN 
        customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    WHERE 
        hd.hd_income_band_sk IN (SELECT ib.ib_income_band_sk FROM income_band ib WHERE ib.ib_upper_bound > 50000)
    GROUP BY 
        hd.hd_demo_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    hid.customer_count
FROM 
    TopCustomers tc
LEFT JOIN 
    HighIncomeDemographics hid ON tc.c_customer_sk = hid.hd_demo_sk 
WHERE 
    tc.sales_density <= 10
ORDER BY 
    tc.total_sales DESC
LIMIT 50;
