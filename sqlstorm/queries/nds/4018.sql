
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
        c.c_current_cdemo_sk IS NOT NULL
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
        RANK() OVER (ORDER BY cs.total_sales DESC) as sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_sales > 1000
),
SalesDetails AS (
    SELECT 
        c.c_customer_sk,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_sold_date_sk,
        d.d_date
    FROM 
        web_sales ws
    INNER JOIN 
        TopCustomers c ON ws.ws_bill_customer_sk = c.c_customer_sk 
    INNER JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.sales_rank,
    sd.ws_order_number,
    sd.ws_ext_sales_price,
    sd.d_date
FROM 
    TopCustomers tc
LEFT JOIN 
    SalesDetails sd ON tc.c_customer_sk = sd.c_customer_sk
WHERE 
    sd.ws_ext_sales_price IS NOT NULL
ORDER BY 
    tc.sales_rank, sd.d_date DESC
LIMIT 100;
