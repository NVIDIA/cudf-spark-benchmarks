
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        customer AS c
    JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        c.c_customer_id, cd.cd_gender
),
TopCustomers AS (
    SELECT 
        c_customer_id,
        cd_gender,
        total_sales,
        order_count,
        DENSE_RANK() OVER (PARTITION BY cd_gender ORDER BY total_sales DESC) AS sales_rank
    FROM CustomerSales
)
SELECT 
    tc.c_customer_id,
    tc.cd_gender,
    tc.total_sales,
    tc.order_count
FROM 
    TopCustomers AS tc
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.cd_gender, tc.total_sales DESC;
