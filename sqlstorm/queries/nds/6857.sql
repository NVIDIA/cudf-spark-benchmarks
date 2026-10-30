
WITH SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        date_part('year', d.d_date) AS sales_year
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
    GROUP BY 
        ws.ws_bill_customer_sk, cd.cd_gender, cd.cd_marital_status, sales_year
), RankedSales AS (
    SELECT 
        *,
        DENSE_RANK() OVER (PARTITION BY sales_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    sales_year,
    cd_gender,
    cd_marital_status,
    total_sales,
    order_count,
    avg_net_profit
FROM 
    RankedSales
WHERE 
    sales_rank <= 10 
ORDER BY 
    sales_year, total_sales DESC;
