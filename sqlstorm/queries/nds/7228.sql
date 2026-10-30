
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS average_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 365
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        cst.c_customer_id,
        cst.total_sales,
        RANK() OVER (ORDER BY cst.total_sales DESC) AS rank
    FROM 
        CustomerSales cst
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    cs.cd_gender,
    cs.cd_marital_status
FROM 
    TopCustomers tc
JOIN 
    CustomerSales cs ON tc.c_customer_id = cs.c_customer_id
WHERE 
    tc.rank <= 100
ORDER BY 
    tc.total_sales DESC;
