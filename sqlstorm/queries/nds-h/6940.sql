WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost, 
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
HighCostSuppliers AS (
    SELECT 
        r.r_name AS region_name, 
        SUM(RankedSuppliers.total_supply_cost) AS region_total_supply_cost
    FROM 
        RankedSuppliers
    JOIN 
        nation n ON RankedSuppliers.nation_name = n.n_name
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        RankedSuppliers.rank <= 3
    GROUP BY 
        r.r_name
)
SELECT 
    r.region_name, 
    r.region_total_supply_cost,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(o.o_totalprice) AS average_order_value
FROM 
    HighCostSuppliers r
LEFT JOIN 
    orders o ON o.o_orderkey IN (SELECT DISTINCT l.l_orderkey FROM lineitem l JOIN partsupp ps ON l.l_partkey = ps.ps_partkey WHERE ps.ps_supplycost > 1000)
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
GROUP BY 
    r.region_name, r.region_total_supply_cost
ORDER BY 
    r.region_total_supply_cost DESC;
