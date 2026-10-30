WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopNations AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        SUM(r.total_supply_cost) AS nation_supply_cost
    FROM 
        nation n
    JOIN 
        RankedSuppliers r ON n.n_nationkey = r.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        SUM(r.total_supply_cost) > (SELECT AVG(total_supply_cost) FROM RankedSuppliers)
),
OrderStatistics AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    tn.n_name, 
    os.o_orderdate, 
    os.total_revenue
FROM 
    TopNations tn
JOIN 
    OrderStatistics os ON tn.n_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
ORDER BY 
    os.total_revenue DESC
LIMIT 10;
