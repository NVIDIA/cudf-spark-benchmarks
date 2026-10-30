
WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        CONCAT(s.s_name, ' located at ', s.s_address) AS supplier_details
    FROM 
        supplier s
), 
ProductInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        CONCAT(p.p_name, ' (Brand: ', p.p_brand, ') priced at $', CAST(p.p_retailprice AS STRING)) AS product_details
    FROM 
        part p
), 
SalesData AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS line_item_count,
        CONCAT('Order ', o.o_orderkey, ' on ', CAST(o.o_orderdate AS STRING), ' with total sales: $', CAST(SUM(l.l_extendedprice * (1 - l.l_discount)) AS STRING)) AS sales_description
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), 
CombinedInfo AS (
    SELECT 
        si.supplier_details,
        pi.product_details,
        sd.sales_description,
        sd.total_sales
    FROM 
        SupplierInfo si
    JOIN 
        partsupp ps ON si.s_suppkey = ps.ps_suppkey
    JOIN 
        ProductInfo pi ON ps.ps_partkey = pi.p_partkey
    JOIN 
        SalesData sd ON sd.line_item_count > 0
)
SELECT 
    supplier_details,
    product_details,
    sales_description
FROM 
    CombinedInfo
WHERE 
    supplier_details LIKE '%United%'
ORDER BY 
    total_sales DESC
LIMIT 10;
