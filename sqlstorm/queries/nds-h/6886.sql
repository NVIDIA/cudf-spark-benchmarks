WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_regionkey
),
TopRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT ns.n_nationkey) AS nation_count
    FROM 
        region r
    LEFT JOIN 
        nation ns ON r.r_regionkey = ns.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    tr.r_name AS region_name,
    rs.s_name AS supplier_name,
    os.o_orderkey,
    os.o_orderdate,
    os.revenue,
    os.unique_parts,
    tr.nation_count
FROM 
    TopRegions tr
JOIN 
    RankedSuppliers rs ON tr.nation_count > 5  
JOIN 
    OrderStats os ON os.revenue > 10000           
WHERE 
    rs.supplier_rank <= 3                          
ORDER BY 
    tr.r_name, os.revenue DESC;