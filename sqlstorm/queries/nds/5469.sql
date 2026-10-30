
WITH SalesStats AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_amount,
        AVG(ws.ws_net_profit) AS average_profit_per_sale,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
        AND cd.cd_gender = 'F'
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        ss.total_quantity_sold,
        ss.total_sales_amount,
        ss.average_profit_per_sale,
        ss.order_count,
        RANK() OVER (ORDER BY ss.total_sales_amount DESC) AS rank
    FROM 
        SalesStats ss
    JOIN 
        customer c ON ss.c_customer_sk = c.c_customer_sk
)
SELECT 
    tc.c_customer_id,
    tc.total_quantity_sold,
    tc.total_sales_amount,
    tc.average_profit_per_sale,
    tc.order_count
FROM 
    TopCustomers tc
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_sales_amount DESC;
