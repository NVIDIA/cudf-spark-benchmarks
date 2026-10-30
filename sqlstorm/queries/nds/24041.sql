WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
FilteredSales AS (
    SELECT 
        s.ws_bill_customer_sk,
        s.total_sales,
        s.order_count,
        s.avg_profit,
        rc.c_first_name,
        rc.c_last_name
    FROM 
        SalesData s
    JOIN 
        RankedCustomers rc ON s.ws_bill_customer_sk = rc.c_customer_sk
    WHERE 
        rc.rank <= 10 AND
        s.total_sales IS NOT NULL
),
FinalReport AS (
    SELECT 
        f.c_first_name,
        f.c_last_name,
        COALESCE(f.total_sales, 0) AS total_sales,
        f.order_count,
        ROUND(f.avg_profit, 2) AS avg_profit
    FROM 
        FilteredSales f
    WHERE 
        f.total_sales > (SELECT AVG(total_sales) FROM SalesData) 
    UNION ALL
    SELECT 
        'Unknown' AS c_first_name,
        'Customer' AS c_last_name,
        SUM(CASE WHEN f.total_sales IS NULL THEN 0 ELSE f.total_sales END) AS total_sales,
        SUM(f.order_count) AS order_count,
        SUM(f.avg_profit) / COUNT(f.order_count) AS avg_profit
    FROM 
        FilteredSales f
    WHERE 
        f.total_sales IS NULL
)
SELECT 
    fr.c_first_name, 
    fr.c_last_name, 
    fr.total_sales, 
    fr.order_count, 
    fr.avg_profit,
    CASE 
        WHEN fr.total_sales > 1000 THEN 'High Value'
        WHEN fr.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS value_category
FROM 
    FinalReport fr
ORDER BY 
    fr.total_sales DESC NULLS LAST;