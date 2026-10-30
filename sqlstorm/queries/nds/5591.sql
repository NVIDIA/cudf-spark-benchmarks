
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 30
    GROUP BY 
        c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk, 
        cs.total_sales, 
        cs.order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cs.total_sales > (
            SELECT 
                AVG(total_sales) 
            FROM 
                CustomerSales
        )
),
SalesDetails AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.total_sales, 
        hvc.order_count,
        d.d_date,
        i.i_item_desc,
        i.i_current_price,
        ws.ws_quantity
    FROM 
        HighValueCustomers hvc
    JOIN 
        web_sales ws ON hvc.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
)
SELECT 
    hvc.c_customer_sk, 
    hvc.total_sales, 
    hvc.order_count,
    COUNT(DISTINCT sd.d_date) AS active_days,
    SUM(sd.ws_quantity) AS total_quantity,
    AVG(sd.i_current_price) AS avg_item_price
FROM 
    HighValueCustomers hvc
JOIN 
    SalesDetails sd ON hvc.c_customer_sk = sd.c_customer_sk
GROUP BY 
    hvc.c_customer_sk, 
    hvc.total_sales, 
    hvc.order_count
ORDER BY 
    hvc.total_sales DESC
LIMIT 100;
