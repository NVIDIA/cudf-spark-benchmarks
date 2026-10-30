
WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY nation_name ORDER BY total_supply_cost DESC) AS supplier_rank
    FROM 
        SupplierSummary
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    ts.nation_name,
    ts.s_suppkey,
    ts.s_name,
    ts.total_available_qty,
    ts.total_supply_cost,
    ro.total_revenue
FROM 
    TopSuppliers ts
LEFT JOIN 
    RecentOrders ro ON ts.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT DISTINCT l.l_partkey FROM lineitem l JOIN orders o ON l.l_orderkey = o.o_orderkey WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '12 months') LIMIT 1)
WHERE 
    ts.supplier_rank <= 5
ORDER BY 
    ts.nation_name, ts.total_supply_cost DESC;
