WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderpriority, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-10-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        COUNT(DISTINCT ps.ps_partkey) AS part_count, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
OrderDetails AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ro.o_orderkey, 
    ro.o_orderdate, 
    ro.o_totalprice, 
    ss.s_suppkey, 
    ss.part_count, 
    ss.total_supply_cost, 
    od.revenue
FROM 
    RankedOrders ro
JOIN 
    SupplierStats ss ON ss.part_count > 5
JOIN 
    OrderDetails od ON od.l_orderkey = ro.o_orderkey
WHERE 
    ro.order_rank <= 10
ORDER BY 
    ro.o_orderdate DESC, 
    od.revenue DESC;