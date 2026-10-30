WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 

TotalSales AS (
    SELECT 
        ws_ship_customer_sk,
        SUM(ws_net_paid) AS total_net_paid
    FROM 
        web_sales
    GROUP BY 
        ws_ship_customer_sk
), 

StoreSales AS (
    SELECT 
        ss_customer_sk,
        SUM(ss_net_paid) AS total_store_paid
    FROM 
        store_sales
    GROUP BY 
        ss_customer_sk
), 

CombinedSales AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(ts.total_net_paid, 0) + COALESCE(ss.total_store_paid, 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        TotalSales ts ON c.c_customer_sk = ts.ws_ship_customer_sk
    LEFT JOIN 
        StoreSales ss ON c.c_customer_sk = ss.ss_customer_sk
), 

FilteredCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        CASE 
            WHEN cs.total_spent IS NULL THEN 'N/A' 
            WHEN cs.total_spent > 1000 THEN 'High spender' 
            ELSE 'Regular' 
        END AS customer_status
    FROM 
        RankedCustomers rc
    LEFT JOIN 
        CombinedSales cs ON rc.c_customer_sk = cs.c_customer_sk
    WHERE 
        rc.rank <= 10
)

SELECT 
    fc.c_customer_sk,
    fc.c_first_name,
    fc.c_last_name,
    fc.customer_status,
    CASE 
        WHEN fc.customer_status = 'High spender' THEN 'Eligible for discount'
        ELSE 'Not eligible for discount'
    END AS discount_status,
    COUNT(DISTINCT p.p_promo_id) AS promotions_available
FROM 
    FilteredCustomers fc
LEFT JOIN 
    promotion p ON (p.p_start_date_sk <= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date = cast('2002-10-01' as date)) 
                    AND p.p_end_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_date = cast('2002-10-01' as date)))
GROUP BY 
    fc.c_customer_sk, 
    fc.c_first_name, 
    fc.c_last_name, 
    fc.customer_status
ORDER BY 
    fc.customer_status DESC, 
    fc.c_last_name, 
    fc.c_first_name;