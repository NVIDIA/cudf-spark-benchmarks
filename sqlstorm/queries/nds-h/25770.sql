WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
NationSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT cs.c_custkey) AS total_customers,
        SUM(o.o_totalprice) AS total_orders
    FROM 
        nation n
    LEFT JOIN 
        customer cs ON n.n_nationkey = cs.c_nationkey
    LEFT JOIN 
        orders o ON cs.c_custkey = o.o_custkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    ns.n_name AS nation,
    rs.s_name AS supplier,
    rs.total_parts AS parts_supplied,
    rs.total_supplycost AS supply_cost,
    ns.total_customers AS customer_count,
    ns.total_orders AS order_total
FROM 
    RankedSuppliers rs
JOIN 
    NationSummary ns ON rs.s_nationkey = ns.n_nationkey
WHERE 
    rs.rank = 1
ORDER BY 
    ns.n_name, rs.total_supplycost DESC;
