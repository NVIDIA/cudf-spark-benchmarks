
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        CD.cd_gender,
        CD.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY CD.cd_gender, CD.cd_marital_status ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
        AND dd.d_month_seq BETWEEN 1 AND 2
    GROUP BY 
        c.c_customer_id, CD.cd_gender, CD.cd_marital_status
)

SELECT 
    rank,
    cd_gender,
    cd_marital_status,
    COUNT(c_customer_id) AS customer_count,
    SUM(total_sales) AS total_sales_amount,
    AVG(total_orders) AS average_orders 
FROM 
    RankedSales
GROUP BY 
    rank, cd_gender, cd_marital_status
HAVING 
    SUM(total_sales) > 1000
ORDER BY 
    cd_gender, cd_marital_status, rank;
