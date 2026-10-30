
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY COUNT(*) DESC) AS rn
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerSummary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(CASE WHEN sr.returned_amt IS NOT NULL THEN sr.returned_amt ELSE 0 END) AS total_returned,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_sold_date_sk) AS last_order_date
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN (
        SELECT 
            sr_customer_sk,
            SUM(sr_return_amt) AS returned_amt
        FROM 
            store_returns
        GROUP BY 
            sr_customer_sk
    ) sr ON c.c_customer_sk = sr.sr_customer_sk
    WHERE 
        ca.ca_city IS NOT NULL
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, ca.ca_city
),
AggregateStats AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(*) AS customer_count,
        AVG(total_sales) AS avg_sales,
        SUM(total_returned) AS total_returned,
        COUNT(order_count) AS total_orders
    FROM 
        CustomerSummary
    GROUP BY 
        cd_gender, cd_marital_status
)
SELECT 
    cs.cd_gender,
    cs.cd_marital_status,
    cs.customer_count,
    cs.avg_sales,
    cs.total_returned,
    cs.total_orders,
    CASE 
        WHEN cs.total_orders IS NULL THEN 'No Orders'
        WHEN cs.total_orders > 0 THEN 'Active Customers' 
        ELSE 'Inactive Customers' 
    END AS customer_status
FROM 
    AggregateStats cs
WHERE 
    cs.customer_count > 10
ORDER BY 
    cs.cd_gender, cs.cd_marital_status;
