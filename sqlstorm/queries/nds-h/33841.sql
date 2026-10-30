WITH  SalesCTE AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1995-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_sales,
        ROW_NUMBER() OVER (ORDER BY ss.total_sales DESC) AS rn
    FROM 
        SalesCTE ss
    JOIN 
        lineitem l ON ss.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, ss.total_sales
    HAVING 
        SUM(l.l_extendedprice) > 10000
)
SELECT 
    r.r_name,
    COUNT(DISTINCT na.n_nationkey) AS nation_count,
    COALESCE(SUM(ts.total_sales), 0) AS total_supplier_sales
FROM 
    region r
LEFT JOIN 
    nation na ON r.r_regionkey = na.n_regionkey
LEFT JOIN 
    TopSuppliers ts ON na.n_nationkey = ts.s_suppkey
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT na.n_nationkey) > 1
ORDER BY 
    total_supplier_sales DESC
LIMIT 10;