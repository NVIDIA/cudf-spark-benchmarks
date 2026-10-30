
WITH SalesData AS (
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_net_paid,
        cs.cs_net_profit,
        d.d_year,
        c.c_birth_year,
        d.d_month_seq
    FROM 
        catalog_sales cs
    JOIN 
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE 
        d.d_year BETWEEN 2018 AND 2022
        AND cs.cs_quantity > 0
), 

SalesSummary AS (
    SELECT 
        d_year,
        c_birth_year,
        SUM(cs_net_paid) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs_order_number) AS order_count
    FROM 
        SalesData
    GROUP BY 
        d_year, c_birth_year
) 

SELECT 
    s.d_year,
    s.c_birth_year,
    s.total_sales,
    s.total_profit,
    s.order_count,
    RANK() OVER (PARTITION BY s.d_year ORDER BY s.total_sales DESC) AS sales_rank
FROM 
    SalesSummary s
ORDER BY 
    s.d_year, sales_rank;
