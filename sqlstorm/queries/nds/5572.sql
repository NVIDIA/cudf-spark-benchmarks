
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count,
        AVG(ss.ss_sales_price) AS avg_purchase_amount,
        MAX(ss.ss_sales_price) AS max_purchase_amount,
        MIN(ss.ss_sales_price) AS min_purchase_amount
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 2450005 AND 2450630  
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
SalesHistory AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450005 AND 2450630  
    GROUP BY 
        c.c_customer_sk
    ORDER BY 
        total_web_sales DESC
    LIMIT 5
),
RetailPerformance AS (
    SELECT
        w.w_warehouse_id,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers
    FROM 
        store_sales ss
    JOIN 
        warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 2450005 AND 2450630  
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_sales,
    cs.purchase_count,
    cs.avg_purchase_amount,
    cs.max_purchase_amount,
    cs.min_purchase_amount,
    sh.total_web_sales,
    rp.w_warehouse_id,
    rp.total_net_profit,
    rp.total_transactions,
    rp.unique_customers
FROM 
    CustomerStats cs
LEFT JOIN 
    SalesHistory sh ON cs.c_customer_sk = sh.c_customer_sk
LEFT JOIN 
    RetailPerformance rp ON rp.unique_customers > 0
WHERE 
    cs.total_sales > 5000  
ORDER BY 
    cs.total_sales DESC;
