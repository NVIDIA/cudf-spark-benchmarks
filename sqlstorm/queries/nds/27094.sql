
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
FilteredData AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        s.total_sales,
        s.order_count,
        s.avg_sales_price
    FROM 
        CustomerInfo ci
    JOIN 
        SalesData s ON ci.c_customer_sk = s.ws_item_sk
)
SELECT 
    fd.full_name,
    fd.ca_city,
    fd.ca_state,
    fd.total_sales,
    fd.order_count,
    fd.avg_sales_price,
    CASE 
        WHEN fd.total_sales > 1000 THEN 'High Sales'
        WHEN fd.total_sales BETWEEN 500 AND 1000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    FilteredData fd
WHERE 
    fd.ca_state IN ('CA', 'NY')
ORDER BY 
    fd.total_sales DESC, fd.order_count DESC;
