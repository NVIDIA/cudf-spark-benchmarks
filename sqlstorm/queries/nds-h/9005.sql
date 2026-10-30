
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        DENSE_RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_nationkey, n.n_name
),
HighCostSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(s.s_suppkey) AS high_cost_count
    FROM 
        RankedSuppliers s
    JOIN 
        nation n ON s.nation = n.n_name
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.rank <= 3
    GROUP BY 
        r.r_name
)
SELECT 
    rc.region_name,
    rc.high_cost_count,
    (SELECT COUNT(DISTINCT c.c_custkey) 
     FROM customer c 
     JOIN orders o ON c.c_custkey = o.o_custkey 
     WHERE o.o_orderstatus = 'F') AS confirmed_orders
FROM 
    HighCostSuppliers rc
ORDER BY 
    rc.region_name;
