
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        MIN(d.d_date) AS first_purchase_date,
        MAX(d.d_date) AS last_purchase_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        cs.first_purchase_date,
        cs.last_purchase_date,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
),
TopNCustomers AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.c_first_name,
        hvc.c_last_name,
        hvc.total_sales,
        hvc.order_count,
        hvc.first_purchase_date,
        hvc.last_purchase_date
    FROM 
        HighValueCustomers hvc
    WHERE 
        hvc.sales_rank <= 10
)
SELECT 
    tnc.c_customer_sk,
    tnc.c_first_name,
    tnc.c_last_name,
    tnc.total_sales,
    tnc.order_count,
    tnc.first_purchase_date,
    tnc.last_purchase_date,
    COUNT(DISTINCT ws.ws_item_sk) AS distinct_items_purchased,
    AVG(ws.ws_sales_price) AS avg_item_price,
    SUM(ws.ws_ext_discount_amt) AS total_discount
FROM 
    TopNCustomers tnc
JOIN 
    web_sales ws ON tnc.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    tnc.c_customer_sk, tnc.c_first_name, tnc.c_last_name, 
    tnc.total_sales, tnc.order_count, tnc.first_purchase_date, 
    tnc.last_purchase_date
ORDER BY 
    tnc.total_sales DESC;
