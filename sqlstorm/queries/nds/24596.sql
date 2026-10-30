
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate, 
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
HighValueCustomers AS (
    SELECT 
        rc.full_name, 
        rc.cd_gender, 
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        RankedCustomers rc
    JOIN 
        web_sales ws ON rc.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        rc.gender_rank <= 5
    GROUP BY 
        rc.full_name, rc.cd_gender
),
StoreSalesSummary AS (
    SELECT 
        s.s_store_id, 
        SUM(ss.ss_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_id
),
TopStores AS (
    SELECT 
        s.s_store_id AS store_id,
        s.total_store_sales
    FROM 
        StoreSalesSummary s
    WHERE 
        s.total_store_sales = (SELECT MAX(total_store_sales) FROM StoreSalesSummary)
)
SELECT 
    hvc.full_name,
    hvc.cd_gender,
    COALESCE(ts.total_store_sales, 0) AS top_store_sales,
    CASE 
        WHEN hvc.cd_gender = 'M' THEN 'Male'
        WHEN hvc.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender_description,
    EXISTS (
        SELECT 
            1 
        FROM 
            reason r 
        WHERE 
            r.r_reason_desc IS NULL OR r.r_reason_desc LIKE '%damaged%'
    ) AS has_invalid_reason
FROM 
    HighValueCustomers hvc
FULL OUTER JOIN 
    TopStores ts ON hvc.cd_gender = 'F' AND hvc.total_spent > 1000
WHERE 
    (hvc.total_spent IS NOT NULL OR ts.total_store_sales IS NULL)
ORDER BY 
    hvc.total_spent DESC NULLS LAST, hvc.full_name;
