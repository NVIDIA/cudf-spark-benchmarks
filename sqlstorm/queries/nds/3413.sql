
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discounts,
        COUNT(ws.ws_order_number) AS orders_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1960 AND 2000
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.*,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales c
)
SELECT 
    t.c_customer_sk,
    t.c_first_name,
    t.c_last_name,
    COALESCE(t.total_sales, 0) AS total_sales,
    COALESCE(t.total_discounts, 0) AS total_discounts,
    t.orders_count,
    w.w_warehouse_name,
    d.d_date AS sales_date,
    CASE 
        WHEN d.d_holiday = 'Y' THEN 'Holiday Sale'
        ELSE 'Regular Sale'
    END AS sale_type
FROM 
    TopCustomers t
LEFT JOIN 
    store_sales ss ON t.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
LEFT JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    sales_rank <= 10 
    AND (t.orders_count > 5 OR t.total_sales > 500)
ORDER BY 
    t.total_sales DESC, sale_type;
