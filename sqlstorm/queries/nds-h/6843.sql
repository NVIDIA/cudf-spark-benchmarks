WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS unique_parts_supplied,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
NationSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(ss.total_supply_cost) AS total_nation_supply_cost,
        SUM(ss.unique_parts_supplied) AS total_unique_parts,
        SUM(ss.total_orders) AS total_orders_per_nation
    FROM 
        nation n
    JOIN 
        SupplierSummary ss ON n.n_nationkey = ss.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name AS region_name,
    ns.n_name AS nation_name,
    ns.total_nation_supply_cost,
    ns.total_unique_parts,
    ns.total_orders_per_nation
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    NationSummary ns ON n.n_nationkey = ns.n_nationkey
ORDER BY 
    r.r_name, ns.n_name;
