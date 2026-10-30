
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
HighValueCustomers AS (
    SELECT 
        ca.ca_address_id AS customer_id,
        cs.total_sales,
        cs.total_orders
    FROM 
        CustomerSales cs
    JOIN 
        customer_address ca ON cs.c_customer_id = ca.ca_address_id
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
        AND ca.ca_city = 'San Francisco'
),
SalesByMonth AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS monthly_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
)
SELECT 
    hvc.customer_id,
    hvc.total_sales,
    hvc.total_orders,
    sbm.d_year,
    sbm.d_month_seq,
    sbm.monthly_sales
FROM 
    HighValueCustomers hvc
JOIN 
    SalesByMonth sbm ON sbm.monthly_sales > 10000
ORDER BY 
    hvc.total_sales DESC, sbm.d_year, sbm.d_month_seq;
