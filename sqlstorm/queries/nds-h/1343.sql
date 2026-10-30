
WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
),
NationRegion AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM 
        nation n
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    nr.n_name,
    nr.region_name,
    COALESCE(SUM(ss.total_sales), 0) AS total_sales_per_nation,
    COUNT(ss.order_count) AS total_orders
FROM 
    NationRegion nr
LEFT JOIN 
    SupplierSales ss ON nr.n_nationkey = ss.s_suppkey 
LEFT JOIN 
    supplier s ON s.s_suppkey = ss.s_suppkey 
LEFT JOIN 
    partsupp ps ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    nr.n_name, nr.region_name
ORDER BY 
    total_sales_per_nation DESC, nr.n_name
LIMIT 10;
