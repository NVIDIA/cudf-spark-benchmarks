
WITH SalesSummary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 100 AND 200
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_preferred_cust_flag,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
),
SalesByCustomer AS (
    SELECT 
        cs.c_customer_sk,
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_net_paid) AS store_sales
    FROM 
        store_sales ss
    JOIN 
        CustomerDetails cs ON ss.ss_customer_sk = cs.c_customer_sk
    GROUP BY 
        cs.c_customer_sk, ss.ss_item_sk
),
AggregatedSales AS (
    SELECT 
        ss.ws_item_sk,
        COALESCE(CAST(SUM(ss.total_quantity) AS DECIMAL(10,2)), 0) AS web_quantity,
        COALESCE(SUM(ss.total_sales), 0) AS web_sales,
        COALESCE(SUM(sb.store_quantity), 0) AS store_quantity,
        COALESCE(SUM(sb.store_sales), 0) AS store_sales
    FROM 
        SalesSummary ss
    LEFT JOIN 
        SalesByCustomer sb ON ss.ws_item_sk = sb.ss_item_sk
    GROUP BY 
        ss.ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    a.web_quantity,
    a.web_sales,
    a.store_quantity,
    a.store_sales
FROM 
    item i
JOIN 
    AggregatedSales a ON i.i_item_sk = a.ws_item_sk
ORDER BY 
    a.web_sales DESC, a.store_sales DESC
LIMIT 10;
