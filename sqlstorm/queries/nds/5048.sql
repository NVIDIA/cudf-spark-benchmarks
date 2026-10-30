
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY 
        c.c_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer_demographics cd
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk, 
        cs.total_sales, 
        cs.avg_sales_price, 
        cs.total_orders,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cs.total_sales > (
            SELECT AVG(total_sales) FROM CustomerSales
        )
    ORDER BY 
        cs.total_sales DESC
    LIMIT 10
)
SELECT 
    tc.c_customer_sk, 
    tc.total_sales, 
    tc.avg_sales_price, 
    tc.total_orders, 
    tc.cd_gender, 
    tc.cd_marital_status, 
    tc.cd_education_status,
    COUNT(DISTINCT ws.ws_order_number) FILTER (WHERE ws.ws_ship_mode_sk = (SELECT sm.sm_ship_mode_sk FROM ship_mode sm WHERE sm.sm_type = 'AIR')) AS air_shipments,
    COUNT(DISTINCT ws.ws_order_number) FILTER (WHERE ws.ws_ship_mode_sk = (SELECT sm.sm_ship_mode_sk FROM ship_mode sm WHERE sm.sm_type = 'GROUND')) AS ground_shipments
FROM 
    TopCustomers tc
LEFT JOIN 
    web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    tc.c_customer_sk, 
    tc.total_sales, 
    tc.avg_sales_price, 
    tc.total_orders, 
    tc.cd_gender, 
    tc.cd_marital_status, 
    tc.cd_education_status
ORDER BY 
    tc.total_sales DESC;
