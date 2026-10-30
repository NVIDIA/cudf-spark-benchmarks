
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_quantity) > 10
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity_sold,
        SUM(cs_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_ext_sales_price) DESC) AS sales_rank
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
    HAVING 
        SUM(cs_quantity) > 10
    ORDER BY 
        total_sales DESC
), AddressDetails AS (
    SELECT
        ca_address_sk,
        ca_city,
        ca_state,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    WHERE 
        ca.ca_state IN ('CA', 'NY')
    GROUP BY 
        ca_address_sk, ca_city, ca_state
)
SELECT 
    sd.ws_item_sk,
    sd.total_quantity_sold,
    sd.total_sales,
    ad.ca_city,
    ad.ca_state,
    ad.customer_count,
    (SELECT COUNT(*) FROM customer WHERE c_birth_year = 1980) AS total_customers_born_1980,
    NULLIF(sd.total_sales, 0) AS net_sales
FROM 
    SalesCTE sd
JOIN 
    AddressDetails ad ON sd.ws_item_sk = ad.ca_address_sk
WHERE 
    sd.sales_rank <= 5
    AND (ad.customer_count IS NOT NULL OR ad.customer_count > 0)
ORDER BY 
    sd.total_sales DESC
LIMIT 10;
