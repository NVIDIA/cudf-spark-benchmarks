
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        customer.c_customer_id,
        customer.c_first_name,
        customer.c_last_name,
        RankedSales.total_sales,
        RankedSales.order_count
    FROM 
        RankedSales
    JOIN 
        customer ON RankedSales.ws_bill_customer_sk = customer.c_customer_sk
    WHERE 
        RankedSales.sales_rank <= 10
),
SalesAnalysis AS (
    SELECT 
        dc.d_year,
        SUM(ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_ext_sales_price) AS avg_order_value
    FROM 
        web_sales
    JOIN 
        date_dim dc ON web_sales.ws_sold_date_sk = dc.d_date_sk
    GROUP BY 
        dc.d_year
)
SELECT 
    ta.c_customer_id,
    ta.c_first_name,
    ta.c_last_name,
    ta.total_sales,
    ta.order_count,
    sa.total_web_sales,
    sa.total_orders,
    sa.avg_order_value
FROM 
    TopCustomers ta
CROSS JOIN 
    SalesAnalysis sa
ORDER BY 
    ta.total_sales DESC;
