
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
RecentOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
)
SELECT 
    r.nation_name, 
    r.total_supply_cost,
    ro.total_value,
    (SELECT SUM(total_value) FROM RecentOrders) AS overall_total_value,
    CASE 
        WHEN r.rank <= 5 THEN 'Top Supplier'
        ELSE 'Regular Supplier'
    END AS supplier_rank
FROM 
    RankedSuppliers r
LEFT JOIN 
    RecentOrders ro ON r.s_suppkey = ro.o_custkey
ORDER BY 
    r.total_supply_cost DESC, 
    ro.total_value DESC;
