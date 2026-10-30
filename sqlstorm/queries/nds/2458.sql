WITH MonthSales AS (
    SELECT 
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS total_customers
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year = 2001
    GROUP BY 
        d.d_month_seq
),
TopMonths AS (
    SELECT 
        ms.d_month_seq, 
        ms.total_sales, 
        ms.total_orders, 
        ms.total_customers,
        RANK() OVER (ORDER BY ms.total_sales DESC) AS sales_rank
    FROM 
        MonthSales ms
),
Demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    tm.d_month_seq, 
    tm.total_sales, 
    tm.total_orders, 
    tm.total_customers,
    d.cd_gender,
    d.cd_marital_status,
    d.customer_count
FROM 
    TopMonths tm
LEFT JOIN 
    Demographics d ON 1=1
WHERE 
    tm.sales_rank <= 5 
ORDER BY 
    tm.total_sales DESC, d.customer_count DESC;