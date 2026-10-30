
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2001
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        r.c_customer_id,
        r.c_first_name,
        r.c_last_name,
        r.total_sales,
        r.order_count
    FROM 
        RankedSales r
    WHERE 
        r.sales_rank <= 10
),
SalesByMonth AS (
    SELECT 
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS total_monthly_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2001
    GROUP BY 
        d.d_month_seq
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    sbm.total_monthly_sales
FROM 
    TopCustomers tc
JOIN 
    SalesByMonth sbm ON EXTRACT(MONTH FROM DATE '2002-10-01') = sbm.d_month_seq
ORDER BY 
    tc.total_sales DESC;
