
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 

TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        stats.total_available_quantity,
        stats.total_supply_cost,
        RANK() OVER (ORDER BY stats.total_supply_cost DESC) AS rank
    FROM 
        SupplierStats stats
    JOIN 
        supplier s ON stats.s_suppkey = s.s_suppkey
),

RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 MONTH'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice
)

SELECT 
    r.r_name AS region,
    ts.s_name AS supplier,
    ro.o_orderkey,
    ro.o_orderdate,
    ro.total_quantity,
    ro.o_totalprice
FROM 
    TopSuppliers ts
JOIN 
    nation n ON ts.s_suppkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    RecentOrders ro ON ts.s_suppkey = ro.o_orderkey
WHERE 
    ts.rank <= 10
ORDER BY 
    r.r_name, ts.total_supply_cost DESC, ro.o_orderdate DESC;
