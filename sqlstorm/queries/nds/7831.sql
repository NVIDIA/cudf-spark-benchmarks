
WITH CustomerStats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS revenue_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_quantity,
        cs.total_sales,
        cs.order_count,
        cs.revenue_rank
    FROM 
        CustomerStats cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.revenue_rank <= 10
),
SalesByDate AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS daily_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        ws.ws_bill_customer_sk IN (SELECT c_customer_sk FROM customer WHERE c_customer_id IN (SELECT c_customer_id FROM TopCustomers))
    GROUP BY 
        d.d_date
)
SELECT 
    d.d_date,
    COALESCE(SUM(sbd.daily_sales), 0) AS total_sales,
    COUNT(DISTINCT tc.c_customer_id) AS number_of_customers
FROM 
    date_dim d
LEFT JOIN 
    SalesByDate sbd ON d.d_date = sbd.d_date
LEFT JOIN 
    TopCustomers tc ON tc.c_customer_id IN (SELECT c_customer_id FROM customer)
WHERE 
    d.d_date BETWEEN '2021-01-01' AND '2021-12-31'
GROUP BY 
    d.d_date
ORDER BY 
    d.d_date;
