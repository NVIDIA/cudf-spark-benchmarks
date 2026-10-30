WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
NationStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(ss.total_supply_cost) AS total_cost,
        AVG(ss.part_count) AS avg_parts_per_supp
    FROM 
        nation n
    JOIN 
        SupplierStats ss ON n.n_nationkey = (
            SELECT s.s_nationkey 
            FROM supplier s 
            WHERE s.s_suppkey IN (SELECT DISTINCT ps.ps_suppkey FROM partsupp ps)
            LIMIT 1) 
    GROUP BY 
        n.n_nationkey, n.n_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' 
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    ns.n_name,
    os.o_orderkey,
    os.total_revenue
FROM 
    NationStats ns
JOIN 
    OrderStats os ON ns.total_cost > 1000000 
ORDER BY 
    ns.n_name, os.total_revenue DESC
LIMIT 10;