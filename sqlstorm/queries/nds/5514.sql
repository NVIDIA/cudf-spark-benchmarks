
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        c_customer_id,
        total_sales,
        avg_net_profit,
        order_count,
        cd_gender,
        cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY total_sales DESC) AS rank
    FROM 
        CustomerSales
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.avg_net_profit,
    tc.order_count,
    tc.cd_gender,
    tc.cd_marital_status
FROM 
    TopCustomers tc
WHERE 
    tc.rank <= 5
ORDER BY 
    tc.cd_gender, tc.total_sales DESC;
