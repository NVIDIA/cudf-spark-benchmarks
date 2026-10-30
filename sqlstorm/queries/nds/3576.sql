
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT 
                d.d_date_sk 
            FROM 
                date_dim d 
            WHERE 
                d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 12
        )
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
AverageSales AS (
    SELECT 
        AVG(total_sales) AS avg_sales,
        AVG(order_count) AS avg_orders
    FROM 
        CustomerSales
),
HighRepeatCustomers AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs.c_customer_sk ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        AverageSales a ON cs.total_sales > a.avg_sales
)
SELECT 
    hrc.c_first_name,
    hrc.c_last_name,
    hrc.total_sales,
    CASE 
        WHEN hrc.total_sales >= 1000 THEN 'High Value'
        ELSE 'Regular Value'
    END AS customer_value_status,
    CASE 
        WHEN hrc.sales_rank <= 5 THEN 1 ELSE 0 
    END AS top_customer_flag
FROM 
    HighRepeatCustomers hrc
WHERE 
    hrc.sales_rank <= 10
ORDER BY 
    hrc.total_sales DESC
LIMIT 10;
