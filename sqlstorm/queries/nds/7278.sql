WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
        AVG(ws.ws_sales_price) AS avg_order_value,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2458849 AND 2459214 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
), RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_sales DESC) AS rank_by_sales
    FROM 
        CustomerSales
)
SELECT 
    r.c_first_name,
    r.c_last_name,
    r.total_sales,
    r.num_orders,
    r.avg_order_value,
    r.cd_gender,
    r.cd_marital_status,
    r.cd_education_status
FROM 
    RankedSales r
WHERE 
    r.rank_by_sales <= 5
ORDER BY 
    r.cd_gender, r.total_sales DESC;