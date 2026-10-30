WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        rs.total_sales,
        rs.order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        RankedSales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
    WHERE 
        rs.sales_rank <= 10
),
SalesByDate AS (
    SELECT 
        d.d_date,
        SUM(ws_ext_sales_price) AS daily_sales,
        COUNT(ws_order_number) AS daily_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_date
)
SELECT 
    tc.c_customer_id,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_purchase_estimate,
    tc.total_sales,
    tc.order_count,
    sbd.d_date,
    sbd.daily_sales,
    sbd.daily_orders
FROM 
    TopCustomers tc
LEFT JOIN 
    SalesByDate sbd ON sbd.d_date >= cast('2002-10-01' as date) - INTERVAL '30 days'
ORDER BY 
    tc.total_sales DESC, sbd.daily_sales DESC
LIMIT 50;