WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_sales_price) AS total_sales, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales 
    JOIN 
        item ON ws_item_sk = i_item_sk
    WHERE 
        i_current_price > 0
    GROUP BY 
        ws_item_sk
), 
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_sales,
        i.i_product_name
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rank <= 10
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS customer_total_spent
    FROM 
        customer c 
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450500 
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
SalesByGender AS (
    SELECT 
        cd.cd_gender,
        SUM(cd.customer_total_spent) AS total_spent_by_gender,
        COUNT(DISTINCT cd.c_customer_sk) AS unique_customers
    FROM 
        CustomerDetails cd
    JOIN 
        TopSales ts ON cd.total_orders > 0
    GROUP BY 
        cd.cd_gender
)
SELECT 
    ts.i_product_name,
    sbg.total_spent_by_gender,
    sbg.unique_customers
FROM 
    TopSales ts
JOIN 
    SalesByGender sbg ON 1=1 
ORDER BY 
    ts.total_sales DESC, sbg.total_spent_by_gender DESC;