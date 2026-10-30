
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales, 
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY 
        ws_item_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk, 
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
    HAVING 
        SUM(ws.ws_net_paid) > 1000
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    w.w_warehouse_name,
    SUM(ss.ss_sales_price) AS total_store_sales,
    COALESCE(hvc.total_spent, 0) AS high_value_customer_spent,
    COUNT(DISTINCT rsc.ws_item_sk) AS unique_items_sold
FROM 
    warehouse w
LEFT JOIN 
    store_sales ss ON w.w_warehouse_sk = ss.ss_store_sk
LEFT JOIN 
    RankedSales rsc ON rsc.ws_item_sk = ss.ss_item_sk
LEFT JOIN 
    HighValueCustomers hvc ON hvc.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    CustomerDemographics cd ON cd.cd_demo_sk = rsc.ws_item_sk 
WHERE 
    w.w_city = 'Los Angeles'
GROUP BY 
    w.w_warehouse_name, hvc.total_spent
HAVING 
    SUM(ss.ss_sales_price) > 50000
ORDER BY 
    total_store_sales DESC;
