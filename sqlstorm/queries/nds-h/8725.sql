
WITH RankedSuppliers AS (
    SELECT 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_name
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
),
OrderDetails AS (
    SELECT 
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS revenue,
        COUNT(lo.l_orderkey) AS line_item_count 
    FROM 
        lineitem lo
    GROUP BY 
        lo.l_orderkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.c_name,
    od.revenue,
    od.line_item_count,
    rs.total_cost
FROM 
    RecentOrders ro
JOIN 
    OrderDetails od ON ro.o_orderkey = od.l_orderkey
JOIN 
    RankedSuppliers rs ON rs.rank <= 10
ORDER BY 
    od.revenue DESC, 
    ro.o_orderdate DESC;
