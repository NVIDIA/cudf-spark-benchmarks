WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        i.i_category
    FROM 
        item i
    WHERE 
        i.i_rec_start_date <= cast('2002-10-01' as date) AND i.i_rec_end_date >= cast('2002-10-01' as date)
),
SalesSummary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    cd.full_name,
    cd.ca_city,
    cd.ca_state,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    cd.cd_credit_rating,
    COALESCE(ss.total_quantity, 0) AS quantity_purchased,
    COALESCE(ss.total_sales, 0.00) AS total_spent,
    i.i_item_desc,
    i.i_current_price,
    i.i_brand,
    i.i_category
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesSummary ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
JOIN 
    ItemDetails i ON i.i_item_sk IN (
        SELECT 
            ws.ws_item_sk 
        FROM 
            web_sales ws 
        WHERE 
            ws.ws_bill_customer_sk = cd.c_customer_sk
    )
ORDER BY 
    total_spent DESC, 
    cd.full_name;