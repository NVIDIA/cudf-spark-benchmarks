
WITH SalesData AS (
    SELECT 
        ss_store_sk,
        SUM(ss_quantity) AS total_quantity_sold,
        SUM(ss_ext_sales_price) AS total_sales,
        AVG(ss_net_paid) AS average_net_paid
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY 
        ss_store_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_country = 'USA'
),
ProductData AS (
    SELECT 
        ws_item_sk,
        COUNT(DISTINCT ws_order_number) AS orders_count,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY 
        ws_item_sk
),
FinalAnalytics AS (
    SELECT 
        cs.cd_gender,
        cs.cd_marital_status,
        SUM(sd.total_quantity_sold) AS sum_total_quantity,
        SUM(sd.total_sales) AS sum_total_sales,
        COUNT(DISTINCT pd.ws_item_sk) AS unique_products_sold,
        SUM(pd.total_profit) AS total_profit_per_item
    FROM 
        SalesData sd
    JOIN 
        CustomerData cs ON sd.ss_store_sk = cs.c_customer_sk
    JOIN 
        ProductData pd ON sd.ss_store_sk = pd.ws_item_sk
    GROUP BY 
        cs.cd_gender, cs.cd_marital_status
)
SELECT 
    cd_gender,
    cd_marital_status,
    sum_total_quantity,
    sum_total_sales,
    unique_products_sold,
    total_profit_per_item
FROM 
    FinalAnalytics
ORDER BY 
    sum_total_sales DESC;
