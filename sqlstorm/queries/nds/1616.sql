
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS rank
    FROM 
        CustomerSales cs 
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
),
LowValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_sales ASC) AS rank
    FROM 
        CustomerSales cs 
    WHERE 
        cs.total_sales <= (SELECT AVG(total_sales) FROM CustomerSales)
),
SalesSummary AS (
    SELECT 
        'High Value' AS customer_segment,
        h.total_sales,
        h.order_count,
        COALESCE(SUM(ws.ws_net_paid_inc_tax), 0) AS additional_sales
    FROM
        HighValueCustomers h
    LEFT JOIN 
        web_sales ws ON h.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        h.total_sales, h.order_count
    HAVING 
        SUM(ws.ws_net_paid_inc_tax) IS NOT NULL

    UNION ALL
    
    SELECT 
        'Low Value' AS customer_segment,
        l.total_sales,
        l.order_count,
        COALESCE(SUM(ws.ws_net_paid_inc_tax), 0) AS additional_sales
    FROM 
        LowValueCustomers l
    LEFT JOIN 
        web_sales ws ON l.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        l.total_sales, l.order_count
    HAVING 
        SUM(ws.ws_net_paid_inc_tax) IS NOT NULL
)
SELECT 
    ss.customer_segment,
    AVG(ss.total_sales) AS avg_sales,
    AVG(ss.order_count) AS avg_order_count,
    SUM(ss.additional_sales) AS total_additional_sales
FROM 
    SalesSummary ss
GROUP BY 
    ss.customer_segment
ORDER BY 
    CASE ss.customer_segment
        WHEN 'High Value' THEN 1
        WHEN 'Low Value' THEN 2
    END;
