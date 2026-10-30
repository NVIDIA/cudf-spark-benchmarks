
WITH CustomerStats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(CASE WHEN ss.ss_net_profit > 0 THEN ss.ss_net_profit ELSE 0 END) AS total_profit,
        COUNT(ss.ss_ticket_number) AS total_sales,
        AVG(ss.ss_net_paid) AS avg_purchase_value,
        COUNT(DISTINCT ss.ss_item_sk) AS unique_items_purchased
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),

HighValueCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_education_status,
        cs.total_profit,
        cs.total_sales,
        cs.avg_purchase_value,
        cs.unique_items_purchased,
        ROW_NUMBER() OVER (ORDER BY cs.total_profit DESC) AS rank
    FROM 
        CustomerStats AS cs
    WHERE 
        cs.total_profit > 1000
        AND cs.total_sales > 5
)

SELECT 
    hv.c_customer_id,
    hv.cd_gender,
    hv.cd_marital_status,
    hv.cd_education_status,
    hv.total_profit,
    hv.total_sales,
    hv.avg_purchase_value,
    hv.unique_items_purchased
FROM 
    HighValueCustomers AS hv
WHERE 
    hv.rank <= 50
ORDER BY 
    hv.total_profit DESC;
