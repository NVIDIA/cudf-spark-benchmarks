
WITH customer_sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND 
        dd.d_moy IN (6, 7) AND 
        c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        ccs.c_customer_sk,
        ccs.c_first_name,
        ccs.c_last_name,
        ccs.total_sales,
        ccs.total_quantity,
        ccs.order_count,
        ROW_NUMBER() OVER (ORDER BY ccs.total_sales DESC) AS rank
    FROM 
        customer_sales_summary ccs
)
SELECT 
    t_c.c_customer_sk,
    COUNT(cr.cr_item_sk) AS total_returns,
    SUM(cr.cr_return_amount) AS return_amount,
    SUM(cr.cr_return_tax) AS return_tax
FROM 
    top_customers t_c
LEFT JOIN 
    catalog_returns cr ON t_c.c_customer_sk = cr.cr_returning_customer_sk
WHERE 
    t_c.rank <= 10
GROUP BY 
    t_c.c_customer_sk, 
    t_c.c_first_name, 
    t_c.c_last_name,
    t_c.total_sales
ORDER BY 
    t_c.total_sales DESC;
