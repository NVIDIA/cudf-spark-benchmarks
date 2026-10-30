
WITH Summary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_spent
    FROM 
        customer AS c
        JOIN store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
        JOIN date_dim AS d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, d.d_year
),
RankedCustomers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY d_year ORDER BY total_spent DESC) AS rank
    FROM 
        Summary
)
SELECT 
    rc.c_customer_id,
    rc.c_first_name,
    rc.c_last_name,
    rc.d_year,
    rc.total_quantity,
    rc.total_spent
FROM 
    RankedCustomers AS rc
WHERE 
    rc.rank <= 10 
ORDER BY 
    rc.d_year, rc.total_spent DESC;
