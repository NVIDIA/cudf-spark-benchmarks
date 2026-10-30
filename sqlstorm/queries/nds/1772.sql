
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        MAX(ws_sold_date_sk) AS last_purchase_date
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
high_value_customers AS (
    SELECT 
        cs_bill_customer_sk,
        SUM(cs_ext_sales_price) AS total_catalog_sales
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2022 AND d_month_seq IN (1, 2, 3)
        )
    GROUP BY 
        cs_bill_customer_sk 
    HAVING 
        SUM(cs_ext_sales_price) > 1000
),
return_summary AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS returns_count,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(cs.total_sales, 0) AS total_sales,
    COALESCE(cs.total_orders, 0) AS total_orders,
    COALESCE(hvc.total_catalog_sales, 0) AS total_catalog_sales,
    COALESCE(rs.returns_count, 0) AS returns_count,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN hvc.total_catalog_sales IS NOT NULL THEN 'High-Value'
        ELSE 'Regular'
    END AS customer_type
FROM 
    customer AS c
LEFT JOIN 
    sales_summary AS cs ON c.c_customer_sk = cs.ws_bill_customer_sk
LEFT JOIN 
    high_value_customers AS hvc ON c.c_customer_sk = hvc.cs_bill_customer_sk
LEFT JOIN 
    return_summary AS rs ON c.c_customer_sk = rs.sr_customer_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 2000
AND 
    (c.c_preferred_cust_flag = 'Y' OR COALESCE(cs.total_sales, 0) > 500)
ORDER BY 
    total_sales DESC, 
    c.c_last_name ASC;
