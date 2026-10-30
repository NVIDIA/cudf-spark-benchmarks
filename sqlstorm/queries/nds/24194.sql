
WITH RankedCustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY c.c_birth_year ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) 
                                AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_id, c.c_birth_year
),
MaxSales AS (
    SELECT 
        birth_year,
        MAX(total_sales) AS max_sales
    FROM 
        (SELECT 
            c.c_birth_year AS birth_year,
            SUM(ws.ws_ext_sales_price) AS total_sales
         FROM 
            customer c
         JOIN 
            web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
         GROUP BY 
            c.c_birth_year
         HAVING 
            SUM(ws.ws_ext_sales_price) IS NOT NULL) AS SalesData
    GROUP BY 
        birth_year
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cs.total_sales,
    CASE 
        WHEN cs.total_sales IS NULL THEN 'NO SALES'
        WHEN cs.total_sales > ms.max_sales THEN 'TOP SPENDER'
        ELSE 'AVERAGE SPENDER'
    END AS spending_category
FROM 
    customer c
LEFT JOIN 
    RankedCustomerSales cs ON c.c_customer_id = cs.c_customer_id
LEFT JOIN 
    MaxSales ms ON c.c_birth_year = ms.birth_year
WHERE 
    (c.c_birth_month = 12 OR c.c_birth_month IS NULL)
AND 
    (cs.sales_rank = 1 OR cs.sales_rank IS NULL)
ORDER BY 
    c.c_last_name, c.c_first_name;
