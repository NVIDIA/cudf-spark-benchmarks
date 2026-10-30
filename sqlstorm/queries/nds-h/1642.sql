
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
),
HighVolumeOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
TopNationSuppliers AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT rs.s_suppkey) AS supplier_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    nh.n_name,
    COALESCE(ts.supplier_count, 0) AS total_suppliers,
    COUNT(hvo.o_orderkey) AS high_volume_orders
FROM 
    nation nh
LEFT JOIN 
    TopNationSuppliers ts ON nh.n_name = ts.n_name
LEFT JOIN 
    HighVolumeOrders hvo ON nh.n_nationkey IN (SELECT DISTINCT s_nationkey FROM supplier WHERE s_suppkey IN (SELECT DISTINCT rs.s_suppkey FROM RankedSuppliers rs WHERE rs.rn = 1)) 
GROUP BY 
    nh.n_name, ts.supplier_count
ORDER BY 
    total_suppliers DESC, high_volume_orders DESC;
