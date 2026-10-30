
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_sales_price) AS avg_sales_per_order,
        RANK() OVER (PARTITION BY c.c_current_addr_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_addr_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_current_addr_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_orders,
        cs.total_sales,
        cs.avg_sales_per_order,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS customer_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.sales_rank <= 5
),
SalesByMonth AS (
    SELECT 
        dd.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS total_month_sales,
        COUNT(ws.ws_order_number) AS orders_count
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON dd.d_date_sk = ws.ws_sold_date_sk
    WHERE
        dd.d_year = 2023
    GROUP BY 
        dd.d_month_seq
),
FinalReport AS (
    SELECT 
        tc.c_customer_id,
        tc.total_orders,
        tc.total_sales,
        sbm.total_month_sales,
        sbm.orders_count
    FROM 
        TopCustomers tc
    LEFT JOIN 
        SalesByMonth sbm ON sbm.orders_count > 100
)
SELECT 
    fr.c_customer_id,
    fr.total_orders,
    fr.total_sales,
    COALESCE(fb.total_month_sales, 0) AS total_sales_last_month,
    CASE 
        WHEN fr.total_sales > 5000 THEN 'High Value'
        WHEN fr.total_sales IS NULL OR fr.total_sales = 0 THEN 'No Sales'
        ELSE 'Regular Value'
    END AS customer_value_category
FROM 
    FinalReport fr
LEFT JOIN 
    SalesByMonth fb ON fb.total_month_sales > 0
WHERE 
    fr.total_orders IS NOT NULL
ORDER BY 
    fr.total_sales DESC;
