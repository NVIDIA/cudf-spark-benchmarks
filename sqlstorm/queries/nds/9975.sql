
WITH SalesData AS (
    SELECT 
        s.s_store_name,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count,
        AVG(ss.ss_net_profit) AS avg_net_profit
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        s.s_store_name
), CustomerData AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(c.c_birth_year) AS avg_birth_year
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)

SELECT 
    sd.s_store_name,
    sd.total_sales,
    sd.transaction_count,
    sd.avg_net_profit,
    cd.cd_gender,
    cd.customer_count,
    cd.avg_birth_year
FROM 
    SalesData sd
LEFT JOIN 
    CustomerData cd ON sd.total_sales > 10000
ORDER BY 
    sd.total_sales DESC, cd.customer_count DESC;
