
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_paid) AS avg_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighSpendingCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.avg_net_paid,
        cs.order_count
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cs.total_sales > 1000 AND cd.cd_gender = 'F'
)
SELECT 
    hsc.c_first_name,
    hsc.c_last_name,
    hsc.total_sales,
    hsc.avg_net_paid,
    hsc.order_count,
    COALESCE(i.i_item_desc, 'No Item Info') AS sample_item
FROM 
    HighSpendingCustomers hsc
LEFT JOIN 
    item i ON hsc.c_customer_sk = i.i_item_sk
ORDER BY 
    hsc.total_sales DESC
LIMIT 10;
