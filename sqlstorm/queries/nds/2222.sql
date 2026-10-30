
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status
    FROM 
        RankedCustomers rc
    WHERE 
        rc.purchase_rank <= 10
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        sd.total_sales,
        sd.order_count
    FROM 
        TopCustomers tc
    LEFT JOIN 
        SalesData sd ON tc.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    COALESCE(cd.total_sales, 0) AS total_sales,
    COALESCE(cd.order_count, 0) AS order_count,
    CASE 
        WHEN cd.total_sales IS NULL OR cd.order_count IS NULL THEN 'No Sales Data'
        ELSE 'Has Sales Data'
    END AS sales_data_status
FROM 
    CombinedData cd
FULL OUTER JOIN 
    customer_address ca ON cd.c_customer_sk = ca.ca_address_sk
WHERE 
    (ca.ca_city = 'New York' OR ca.ca_state = 'NY')
    AND (cd.order_count > 1 OR cd.total_sales > 1000)
ORDER BY 
    cd.total_sales DESC NULLS LAST
LIMIT 50;
