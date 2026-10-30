
WITH SalesData AS (
    SELECT 
        d.d_year,
        SUM(ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss_customer_sk) AS unique_customers,
        AVG(ss_quantity) AS avg_quantity_per_sale,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_ext_discount_amt) AS total_discount
    FROM 
        store_sales 
    INNER JOIN 
        date_dim d ON ss_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
),
BestCustomer AS (
    SELECT 
        c.c_customer_id,
        SUM(ws_net_paid) AS total_spent,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales 
    INNER JOIN 
        customer c ON ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
    ORDER BY 
        total_spent DESC
    LIMIT 10
),
TopStores AS (
    SELECT 
        s.s_store_id,
        SUM(ss_sales_price) AS total_sales
    FROM 
        store_sales 
    INNER JOIN 
        store s ON ss_store_sk = s.s_store_sk
    GROUP BY 
        s.s_store_id
    ORDER BY 
        total_sales DESC
    LIMIT 5
)
SELECT 
    sd.d_year,
    sd.total_net_paid,
    sd.unique_customers,
    sd.avg_quantity_per_sale,
    sd.total_sales,
    sd.total_discount,
    bc.c_customer_id,
    bc.total_spent,
    bc.total_orders,
    ts.s_store_id,
    ts.total_sales
FROM 
    SalesData sd
CROSS JOIN 
    BestCustomer bc
CROSS JOIN 
    TopStores ts
ORDER BY 
    sd.d_year DESC, 
    bc.total_spent DESC, 
    ts.total_sales DESC;
