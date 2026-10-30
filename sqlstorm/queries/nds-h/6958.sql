WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderpriority,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderpriority
),
SupplierSummary AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        r.r_name
)
SELECT 
    os.o_orderkey,
    os.o_orderdate,
    os.total_revenue,
    os.o_orderpriority,
    ss.region_name,
    ss.supplier_count,
    ss.avg_acctbal,
    rs.p_name AS top_supplier_part,
    rs.s_name AS supplier_name,
    rs.ps_availqty AS available_quantity
FROM 
    OrderSummary os
JOIN 
    SupplierSummary ss ON os.item_count = ss.supplier_count 
JOIN 
    RankedSuppliers rs ON os.o_orderkey = rs.s_suppkey
WHERE 
    rs.rn = 1
ORDER BY 
    os.total_revenue DESC, ss.supplier_count ASC;