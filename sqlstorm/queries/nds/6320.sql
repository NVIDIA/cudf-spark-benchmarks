
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
        DATE_DIM.d_year
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
        JOIN date_dim DATE_DIM ON ws.ws_sold_date_sk = DATE_DIM.d_date_sk
    WHERE 
        DATE_DIM.d_year BETWEEN 2020 AND 2022
    GROUP BY 
        c.c_customer_id, cd.cd_gender, DATE_DIM.d_year
),
CustomerRank AS (
    SELECT 
        c_customer_id,
        cd_gender,
        total_sales,
        order_count,
        avg_order_value,
        DENSE_RANK() OVER (PARTITION BY cd_gender ORDER BY total_sales DESC) as sales_rank
    FROM 
        SalesSummary
)
SELECT 
    cr.c_customer_id,
    cr.cd_gender,
    cr.total_sales,
    cr.order_count,
    cr.avg_order_value,
    cr.sales_rank
FROM 
    CustomerRank cr
WHERE 
    cr.sales_rank <= 10
ORDER BY 
    cr.cd_gender, cr.total_sales DESC;
