
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY COALESCE(cd.cd_purchase_estimate, 0) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        COUNT(DISTINCT ws_item_sk) AS items_purchased
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
    HAVING 
        SUM(ws_net_paid) > 1000
),
FrequentReturners AS (
    SELECT 
        wr_returning_customer_sk AS customer_id,
        COUNT(*) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
    HAVING 
        COUNT(*) > 5
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    ss.total_sales,
    ss.total_orders,
    ss.items_purchased,
    COALESCE(fr.return_count, 0) AS return_count
FROM 
    RankedCustomers rc
JOIN 
    SalesSummary ss ON rc.c_customer_sk = ss.customer_id
LEFT JOIN 
    FrequentReturners fr ON rc.c_customer_sk = fr.customer_id
WHERE 
    rc.rank <= 10
ORDER BY 
    ss.total_sales DESC, rc.c_last_name, rc.c_first_name;
