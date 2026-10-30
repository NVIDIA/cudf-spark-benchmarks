WITH SalesData AS (
    SELECT 
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        SUM(ss_ext_discount_amt) AS total_discount,
        SUM(ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2001)
                             AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2001)
    GROUP BY 
        ss_store_sk
),
CustomerData AS (
    SELECT 
        c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c_customer_sk
),
CombinedData AS (
    SELECT 
        s.s_store_name,
        sd.total_sales,
        sd.total_discount,
        sd.total_net_paid,
        sd.total_transactions,
        cd.total_orders,
        cd.avg_purchase_estimate
    FROM 
        SalesData sd
    JOIN 
        store s ON sd.ss_store_sk = s.s_store_sk
    JOIN 
        CustomerData cd ON cd.c_customer_sk = sd.ss_store_sk  
)
SELECT 
    c.s_store_name,
    c.total_sales,
    c.total_discount,
    c.total_net_paid,
    c.total_transactions,
    c.total_orders,
    c.avg_purchase_estimate,
    (c.total_sales - c.total_discount) AS net_revenue,
    (c.total_net_paid / NULLIF(c.total_transactions, 0)) AS avg_net_paid_per_transaction
FROM 
    CombinedData c
ORDER BY 
    net_revenue DESC
LIMIT 10;