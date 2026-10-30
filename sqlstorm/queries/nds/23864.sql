
WITH  CustomerCTE AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        c.c_birth_year, 
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY c.c_current_cdemo_sk ORDER BY c.c_birth_year DESC) AS customer_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), AddressCTE AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
), SalesCTE AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_sales_price) AS total_sales, 
        CASE 
            WHEN SUM(ws.ws_sales_price) > 1000 THEN 'High'
            WHEN SUM(ws.ws_sales_price) BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    cte.c_first_name,
    cte.c_last_name,
    addr.ca_city,
    addr.ca_state,
    sales.total_sales,
    sales.sales_category
FROM 
    CustomerCTE cte
JOIN 
    AddressCTE addr ON cte.c_customer_sk = addr.customer_count
LEFT JOIN 
    SalesCTE sales ON cte.c_current_cdemo_sk = sales.ws_item_sk
WHERE 
    addr.customer_count > (SELECT AVG(customer_count) FROM AddressCTE)
AND 
    (cte.cd_gender = 'F' OR cte.cd_gender IS NULL)
AND 
    (cte.customer_rank = 1 OR EXISTS (SELECT 1 FROM CustomerCTE sub WHERE sub.customer_rank <= 2))
ORDER BY 
    total_sales DESC NULLS LAST;
