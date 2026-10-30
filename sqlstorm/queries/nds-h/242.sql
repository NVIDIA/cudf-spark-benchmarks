
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name AS region_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY r.r_name ORDER BY s.s_acctbal DESC) AS rank_within_region
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        o.o_orderpriority
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND
        o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderpriority
), SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    p.p_name,
    COUNT(DISTINCT fs.o_orderkey) AS order_count,
    COALESCE(SUM(sp.total_avail_qty), 0) AS total_available_qty,
    AVG(fs.total_sales) AS avg_sales,
    MAX(CASE WHEN rs.rank_within_region = 1 THEN rs.s_name END) AS top_supplier,
    r.r_name AS region_name
FROM 
    part p
LEFT JOIN 
    SupplierParts sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN 
    RankedSuppliers rs ON sp.ps_suppkey = rs.s_suppkey
LEFT JOIN 
    FilteredOrders fs ON sp.ps_partkey = fs.o_orderkey
LEFT JOIN 
    nation n ON rs.region_name = n.n_name
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice > 50.00 AND
    (rs.s_acctbal IS NULL OR rs.s_acctbal > 1000.00)
GROUP BY 
    p.p_name, r.r_name
HAVING 
    COUNT(DISTINCT fs.o_orderkey) > 5
ORDER BY 
    avg_sales DESC,
    p.p_name;
