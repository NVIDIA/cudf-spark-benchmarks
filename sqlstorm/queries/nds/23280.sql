
WITH RankedReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(wr_item_sk) AS total_returns,
        SUM(wr_return_amt) AS total_return_amount,
        RANK() OVER (PARTITION BY wr_returning_customer_sk ORDER BY SUM(wr_return_amt) DESC) AS return_rank
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk > (SELECT MAX(d_date_sk) - 30 FROM date_dim WHERE d_holiday = 'Y')
    GROUP BY 
        wr_returning_customer_sk
),
SalesSummary AS (
    SELECT 
        ws_ship_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_ship_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY c.c_last_name) AS state_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_country = 'USA'
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    SUM(ss.total_profit) AS total_sales_profit,
    SUM(rr.total_returns) AS total_returned_items,
    (CASE 
        WHEN SUM(ss.total_profit) IS NULL THEN 'No Profits'
        ELSE CAST(SUM(ss.total_profit) AS varchar(20))
    END) AS profit_status,
    (SELECT COUNT(*) FROM RankedReturns) AS total_returning_customers,
    (SELECT COUNT(*) FROM SalesSummary) AS total_customers_with_sales
FROM 
    CustomerInfo ci
JOIN 
    SalesSummary ss ON ci.c_customer_sk = ss.ws_ship_customer_sk
JOIN 
    RankedReturns rr ON rr.wr_returning_customer_sk = ci.c_customer_sk
WHERE 
    ci.state_rank <= 10
GROUP BY 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.cd_gender
ORDER BY 
    total_returned_items DESC NULLS LAST, 
    total_sales_profit DESC;
