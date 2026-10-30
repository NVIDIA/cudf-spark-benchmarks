
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        COUNT(ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
MaxParts AS (
    SELECT 
        MAX(total_parts) AS max_part_count 
    FROM 
        RankedSuppliers
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.total_parts,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        MaxParts mp ON rs.total_parts = mp.max_part_count
),
NationData AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        n.n_comment
    FROM 
        nation n
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    nd.n_name AS supplier_nation,
    ts.total_parts,
    ts.total_supply_cost,
    SUM(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS discounted_sales,
    AVG(o.o_totalprice) AS avg_order_value
FROM 
    TopSuppliers ts
JOIN 
    supplier s ON ts.s_suppkey = s.s_suppkey
JOIN 
    NationData nd ON s.s_nationkey = nd.n_nationkey
JOIN 
    partsupp ps ON ts.s_suppkey = ps.ps_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
GROUP BY 
    ts.s_suppkey, ts.s_name, nd.n_name, ts.total_parts, ts.total_supply_cost
ORDER BY 
    ts.total_supply_cost DESC, ts.total_parts DESC
LIMIT 10;
