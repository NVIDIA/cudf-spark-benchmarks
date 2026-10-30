
WITH  PreviousSales AS (
    SELECT 
        ss_item_sk,
        ss_sold_date_sk,
        ss_quantity,
        ss_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY ss_sold_date_sk DESC) AS rn
    FROM store_sales
), CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_sales
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_first_name IS NOT NULL 
        AND ws.ws_net_paid > 0
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
), HighValueCustomers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.total_sales,
        RANK() OVER (ORDER BY ci.total_sales DESC) AS sales_rank
    FROM CustomerInfo ci
    WHERE ci.total_sales > 50000
), ItemSales AS (
    SELECT 
        ps.ss_item_sk,
        SUM(ps.ss_quantity) AS total_quantity,
        SUM(ps.ss_sales_price * ps.ss_quantity) AS total_revenue
    FROM PreviousSales ps
    WHERE ps.rn = 1
    GROUP BY ps.ss_item_sk
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    its.total_quantity,
    its.total_revenue,
    CASE 
        WHEN hvc.cd_gender = 'M' THEN 'Male'
        WHEN hvc.cd_gender = 'F' THEN 'Female'
        ELSE 'Unknown'
    END AS formatted_gender
FROM HighValueCustomers hvc
LEFT JOIN ItemSales its ON hvc.c_customer_sk = its.ss_item_sk
WHERE hvc.sales_rank <= 100
ORDER BY hvc.total_sales DESC, its.total_revenue DESC
LIMIT 50;
