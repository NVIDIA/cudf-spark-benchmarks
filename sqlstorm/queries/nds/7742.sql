
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 10000 AND 10005
    GROUP BY 
        c.c_customer_id, cd.cd_gender
),
RankedSales AS (
    SELECT 
        cs.c_customer_id AS customer_id,
        cs.cd_gender,
        cs.total_sales,
        cs.total_orders,
        RANK() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
),
TopCustomers AS (
    SELECT 
        r.customer_id,
        r.cd_gender,
        r.total_sales,
        r.total_orders
    FROM 
        RankedSales r
    WHERE 
        r.sales_rank <= 10
)
SELECT 
    tc.cd_gender,
    COUNT(*) AS num_customers,
    AVG(tc.total_sales) AS avg_sales,
    SUM(tc.total_orders) AS total_orders
FROM 
    TopCustomers tc
GROUP BY 
    tc.cd_gender
ORDER BY 
    avg_sales DESC;
