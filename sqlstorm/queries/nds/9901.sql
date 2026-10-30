
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
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
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
),
SalesByMonth AS (
    SELECT 
        EXTRACT(YEAR FROM d.d_date) AS sales_year,
        EXTRACT(MONTH FROM d.d_date) AS sales_month,
        SUM(ws.ws_ext_sales_price) AS monthly_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        EXTRACT(YEAR FROM d.d_date), EXTRACT(MONTH FROM d.d_date)
),
CombinedSales AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.total_sales,
        tc.order_count,
        sbm.sales_year,
        sbm.sales_month,
        sbm.monthly_sales
    FROM 
        TopCustomers tc
    JOIN 
        SalesByMonth sbm ON tc.sales_rank <= 10
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_sales,
    cs.order_count,
    ms.sales_year,
    ms.sales_month,
    ms.monthly_sales,
    CASE 
        WHEN cs.total_sales > 10000 THEN 'High Value Customer' 
        ELSE 'Standard Customer' 
    END AS customer_segment
FROM 
    CombinedSales cs
JOIN 
    SalesByMonth ms ON cs.sales_year = ms.sales_year AND cs.sales_month = ms.sales_month
ORDER BY 
    cs.total_sales DESC, ms.sales_year DESC, ms.sales_month DESC;
