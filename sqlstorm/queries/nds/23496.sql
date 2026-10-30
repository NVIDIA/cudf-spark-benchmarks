
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_web_page_sk) AS unique_web_pages
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year > 1980
        AND c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_customer_id,
        cs.total_sales,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
),
PotentialFraud AS (
    SELECT 
        c.c_customer_id,
        c.c_customer_sk,
        CASE 
            WHEN COUNT(ws.ws_order_number) > 10 AND SUM(ws.ws_net_paid) < 100 THEN 'Possible Fraud'
            ELSE 'Normal'
        END AS fraud_status
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_customer_sk
),
SalesSummary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_shipments,
        COUNT(DISTINCT CASE WHEN ws.ws_ship_mode_sk IS NULL THEN 'Shipped via Unknown Mode' END) AS unknown_shipments
    FROM 
        web_sales ws
    LEFT JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sales_price IS NOT NULL
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.total_orders,
    sf.fraud_status,
    ss.total_net_profit,
    ss.total_shipments,
    ss.unknown_shipments
FROM 
    TopCustomers tc
FULL OUTER JOIN 
    PotentialFraud sf ON tc.c_customer_id = sf.c_customer_id
FULL OUTER JOIN 
    SalesSummary ss ON tc.c_customer_id IS NOT NULL
WHERE 
    (tc.sales_rank <= 10 OR sf.fraud_status = 'Possible Fraud')
    AND ss.total_net_profit IS NOT NULL
ORDER BY 
    tc.total_sales DESC NULLS LAST;
