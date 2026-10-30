
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
), 
AvailableParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_suppkey) AS supplier_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)

SELECT 
    r.r_name,
    COUNT(DISTINCT ap.ps_partkey) AS part_count,
    COALESCE(SUM(ap.total_available_quantity), 0) AS available_quantity,
    MAX(od.total_price) AS max_order_value,
    SUM(CASE WHEN rs.rnk = 1 THEN rs.s_acctbal ELSE 0 END) AS top_nation_supplier_balance
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
LEFT JOIN 
    AvailableParts ap ON s.s_suppkey = ap.ps_partkey
LEFT JOIN 
    OrderDetails od ON s.s_suppkey = od.o_orderkey
WHERE 
    r.r_name IS NOT NULL AND (s.s_acctbal IS NOT NULL OR rs.rnk IS NOT NULL)
GROUP BY 
    r.r_name, s.s_suppkey, s.s_name, s.s_acctbal, rs.rnk
HAVING 
    COUNT(DISTINCT ap.ps_partkey) > 5
ORDER BY 
    available_quantity DESC;
