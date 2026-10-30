
WITH  SalesSummary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS sales_rank
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
), TopCustomers AS (
    SELECT
        cs_bill_customer_sk,
        SUM(cs_net_profit) AS total_net_profit
    FROM
        catalog_sales
    GROUP BY
        cs_bill_customer_sk
), CombinedSales AS (
    SELECT
        ws.ws_bill_customer_sk,
        COALESCE(ws.total_net_profit, 0) AS web_net_profit,
        COALESCE(cs.total_net_profit, 0) AS catalog_net_profit
    FROM
        SalesSummary ws
    FULL OUTER JOIN
        TopCustomers cs ON ws.ws_bill_customer_sk = cs.cs_bill_customer_sk
)
SELECT
    c.c_first_name,
    c.c_last_name,
    COALESCE(cs.web_net_profit, 0) AS web_sales,
    COALESCE(cs.catalog_net_profit, 0) AS catalog_sales,
    (COALESCE(cs.web_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0)) AS total_sales,
    CASE 
        WHEN (COALESCE(cs.web_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0)) = 0 THEN 'No Sales'
        WHEN (COALESCE(cs.web_net_profit, 0) > COALESCE(cs.catalog_net_profit, 0)) THEN 'Web Sales Dominant'
        ELSE 'Catalog Sales Dominant'
    END AS sales_type
FROM
    customer c
LEFT JOIN
    CombinedSales cs ON c.c_customer_sk = cs.ws_bill_customer_sk
WHERE
    (c.c_birth_year BETWEEN 1970 AND 1990) 
    AND (c.c_preferred_cust_flag IS NOT NULL OR c.c_email_address IS NOT NULL)
ORDER BY
    total_sales DESC
LIMIT 100;
