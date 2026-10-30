WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 10000
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, l.l_partkey
)
SELECT 
    p.p_name,
    p.p_brand,
    COALESCE(SUM(od.total_revenue), 0) AS total_revenue,
    COALESCE(SUM(CASE WHEN rs.rn = 1 THEN s.s_acctbal ELSE NULL END), 0) AS top_supplier_acctbal
FROM 
    part p
LEFT JOIN 
    OrderDetails od ON p.p_partkey = od.l_partkey
LEFT JOIN 
    RankedSuppliers rs ON p.p_partkey = rs.s_suppkey
LEFT JOIN 
    supplier s ON rs.s_suppkey = s.s_suppkey
GROUP BY 
    p.p_name, p.p_brand
HAVING 
    SUM(od.total_revenue) > 50000 OR COUNT(od.o_orderkey) > 10
ORDER BY 
    total_revenue DESC, p.p_name;