
WITH RecursiveCTE AS (
    SELECT 
        c.c_customer_sk,
        c.c_email_address,
        COUNT(ss.ss_ticket_number) AS TotalStoreSales,
        SUM(ss.ss_net_paid) AS TotalNetPaid,
        SUM(ss.ss_quantity) AS TotalQuantity,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ss.ss_net_paid) DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_email_address
    HAVING 
        SUM(ss.ss_net_paid) > 1000 OR COUNT(ss.ss_ticket_number) > 5
),
HighValueCustomers AS (
    SELECT 
        r.c_customer_sk,
        r.c_email_address,
        r.TotalStoreSales,
        r.TotalNetPaid,
        r.TotalQuantity,
        ROW_NUMBER() OVER (ORDER BY r.TotalNetPaid DESC) AS rank
    FROM 
        RecursiveCTE r
    WHERE 
        r.TotalStoreSales > (
            SELECT AVG(TotalStoreSales) FROM RecursiveCTE
        )
),
DateInfo AS (
    SELECT 
        d.d_date_sk,
        d.d_date,
        d.d_week_seq,
        d.d_month_seq,
        d.d_year,
        CASE 
            WHEN MOD(EXTRACT(DOW FROM d.d_date) + 1, 7) = 0 THEN 'Weekend'
            ELSE 'Weekday'
        END AS DayType
    FROM 
        date_dim d
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_email_address,
    COALESCE(hvc.TotalNetPaid, 0) AS TotalNetPaid,
    di.d_date,
    di.DayType,
    COALESCE(hvc.TotalQuantity, 0) AS QuantityPurchased,
    CASE 
        WHEN hvc.TotalNetPaid IS NULL THEN 'No Purchases'
        ELSE 'Purchases Made'
    END AS PurchaseStatus
FROM 
    HighValueCustomers hvc
FULL OUTER JOIN 
    DateInfo di ON 1=1
WHERE 
    di.d_date BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    AND (COALESCE(hvc.TotalNetPaid, 0) > 3000 OR (di.DayType = 'Weekend' AND hvc.TotalStoreSales > 10))
ORDER BY 
    COALESCE(hvc.TotalNetPaid, 0) DESC, 
    di.d_date ASC
LIMIT 100 OFFSET 10;
