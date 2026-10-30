
WITH SalesData AS (
    SELECT 
        cs_bill_customer_sk AS customer_id,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(cs_order_number) AS total_orders,
        SUM(cs_ext_discount_amt) AS total_discounts,
        SUM(cs_ext_tax) AS total_tax,
        MAX(cs_sold_date_sk) AS last_purchase_date
    FROM 
        catalog_sales 
    WHERE 
        cs_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        cs_bill_customer_sk
),
RankedCustomers AS (
    SELECT 
        customer_id, 
        total_sales, 
        total_orders, 
        total_discounts,
        total_tax,
        last_purchase_date,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    c.c_email_address, 
    r.total_sales, 
    r.total_orders, 
    r.total_discounts, 
    r.total_tax, 
    d.d_date AS last_purchase_date
FROM 
    RankedCustomers r
JOIN 
    customer c ON r.customer_id = c.c_customer_sk
JOIN 
    date_dim d ON r.last_purchase_date = d.d_date_sk
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.total_sales DESC;
