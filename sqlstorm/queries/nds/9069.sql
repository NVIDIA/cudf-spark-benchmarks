
WITH CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(c_customer_sk) FILTER (WHERE cd_marital_status = 'M') AS married_customers
    FROM 
        customer_demographics
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_gender
),
SalesData AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk
),
Results AS (
    SELECT 
        cs.cd_gender,
        cs.customer_count,
        cs.avg_purchase_estimate,
        cs.married_customers,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.order_count, 0) AS order_count
    FROM 
        CustomerStats cs
    LEFT JOIN 
        SalesData sd ON cs.customer_count = sd.ws_bill_cdemo_sk
)
SELECT 
    r.cd_gender,
    r.customer_count,
    r.avg_purchase_estimate,
    r.married_customers,
    r.total_sales,
    r.order_count,
    (r.total_sales / NULLIF(r.order_count, 0)) AS avg_sales_per_order,
    (r.avg_purchase_estimate - (r.total_sales / NULLIF(r.customer_count, 0))) AS purchase_diff
FROM 
    Results r
WHERE 
    r.customer_count > 1000
ORDER BY 
    r.total_sales DESC;
