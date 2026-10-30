
WITH RecursiveSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number DESC) AS rec_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= 2458611
), 
TopSales AS (
    SELECT 
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_sales_price,
        r.ws_quantity,
        SUM(r.ws_sales_price * r.ws_quantity) OVER (PARTITION BY r.ws_item_sk) AS total_sales
    FROM 
        RecursiveSales r
    WHERE 
        r.rec_rank <= 5
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, ca.ca_city, ca.ca_state
),
SalesRanked AS (
    SELECT 
        cs.ws_item_sk,
        cs.total_sales,
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.order_count,
        RANK() OVER (PARTITION BY cs.ws_item_sk ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        TopSales cs
    JOIN 
        CustomerDetails cd ON cs.ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_current_price IS NOT NULL)
)

SELECT 
    sr.sales_rank,
    sr.ws_item_sk,
    sr.total_sales,
    cd.c_first_name,
    cd.c_last_name,
    cd.order_count,
    CASE 
        WHEN cd.order_count IS NULL THEN 'No Orders'
        ELSE 'Orders Present'
    END AS order_status,
    COUNT(*) OVER (PARTITION BY sr.ws_item_sk) AS rank_count
FROM 
    SalesRanked sr
JOIN 
    CustomerDetails cd ON sr.c_customer_sk = cd.c_customer_sk
WHERE 
    sr.sales_rank <= 10
ORDER BY 
    sr.ws_item_sk,
    sr.sales_rank;
