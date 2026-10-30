
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        c.c_email_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
ItemData AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_product_name,
        i.i_current_price
    FROM 
        item i
),
SalesData AS (
    SELECT 
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_sold_date_sk
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk >= (
            SELECT MIN(d.d_date_sk)
            FROM date_dim d
            WHERE d.d_year = 2023
        )
),
AggregatedData AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(sd.ss_quantity) AS total_quantity_sold,
        SUM(sd.ss_net_paid) AS total_sales,
        COUNT(DISTINCT sd.ss_item_sk) AS unique_items_sold
    FROM 
        CustomerData cd
    JOIN 
        SalesData sd ON cd.c_customer_sk = sd.ss_item_sk
    GROUP BY 
        cd.full_name, cd.cd_gender, cd.cd_marital_status
)

SELECT 
    ad.full_name,
    ad.cd_gender,
    ad.cd_marital_status,
    ad.total_quantity_sold,
    ad.total_sales,
    ad.unique_items_sold,
    ROW_NUMBER() OVER (ORDER BY ad.total_sales DESC) AS rank
FROM 
    AggregatedData ad
ORDER BY 
    total_sales DESC
LIMIT 100;
