
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_customer_id,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_purchase_estimate
    FROM 
        RankedCustomers rc
    WHERE 
        rc.purchase_rank <= 5
),
SalesSummary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
SalesWithNullCheck AS (
    SELECT 
        t.c_customer_id,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.order_count, 0) AS order_count
    FROM 
        TopCustomers t
    LEFT JOIN 
        SalesSummary ss ON t.c_customer_sk = ss.ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        tw.c_customer_id,
        tw.total_sales,
        tw.order_count,
        CASE 
            WHEN tw.total_sales > 1000 THEN 'High'
            WHEN tw.total_sales BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS customer_segment
    FROM 
        SalesWithNullCheck tw
)
SELECT 
    fr.customer_segment,
    COUNT(*) AS customer_count,
    SUM(fr.total_sales) AS total_segment_sales,
    AVG(fr.order_count) AS average_orders_per_customer
FROM 
    FinalReport fr
GROUP BY 
    fr.customer_segment
ORDER BY 
    CASE fr.customer_segment 
        WHEN 'High' THEN 1 
        WHEN 'Medium' THEN 2 
        WHEN 'Low' THEN 3 
    END;
