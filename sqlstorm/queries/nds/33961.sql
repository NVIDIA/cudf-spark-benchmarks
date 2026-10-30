
WITH  SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number DESC) AS rn
    FROM 
        web_sales
),
CombinedSales AS (
    SELECT 
        cs_order_number AS order_num,
        cs_item_sk AS item_sk,
        cs_quantity AS quantity,
        cs_sales_price AS price,
        cs_ext_sales_price AS ext_price,
        'Catalog' AS source
    FROM 
        catalog_sales
    UNION ALL
    SELECT 
        ss_ticket_number AS order_num,
        ss_item_sk AS item_sk,
        ss_quantity AS quantity,
        ss_sales_price AS price,
        ss_ext_sales_price AS ext_price,
        'Store' AS source
    FROM 
        store_sales
),
TotalSales AS (
    SELECT 
        item_sk,
        SUM(quantity) AS total_quantity,
        SUM(ext_price) AS total_ext_price,
        COUNT(DISTINCT order_num) AS order_count
    FROM 
        CombinedSales
    GROUP BY 
        item_sk
),
TopItems AS (
    SELECT 
        item_sk,
        total_quantity,
        total_ext_price,
        order_count,
        RANK() OVER (ORDER BY total_ext_price DESC) AS rank
    FROM 
        TotalSales
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_customer_sk) AS rn
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE 
        ca.ca_state IN ('CA', 'NY') AND 
        cd.cd_marital_status = 'M'
),
FinalReport AS (
    SELECT 
        ci.c_first_name, 
        ci.c_last_name, 
        ci.ca_state, 
        ti.item_sk,
        ti.total_quantity,
        ti.total_ext_price,
        ti.order_count
    FROM 
        TopItems ti
    JOIN 
        CustomerInfo ci ON ci.rn = ti.rank
    WHERE 
        ti.rank <= 10
)
SELECT 
    fr.c_first_name,
    fr.c_last_name,
    fr.ca_state,
    SUM(fr.total_ext_price) OVER (PARTITION BY fr.ca_state) AS state_total_sales,
    AVG(fr.total_quantity) OVER (PARTITION BY fr.ca_state) AS avg_quantity_sold,
    COUNT(*) OVER () AS total_customers_reported
FROM 
    FinalReport fr
ORDER BY 
    fr.total_ext_price DESC;
