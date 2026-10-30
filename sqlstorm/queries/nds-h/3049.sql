WITH SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_quantity) AS total_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(sp.total_supply_cost) AS total_cost
    FROM 
        supplier s
    JOIN 
        SupplierCost sp ON s.s_suppkey = sp.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedOrders AS (
    SELECT 
        co.o_orderkey,
        co.total_revenue,
        COALESCE(SUM(tc.total_cost), 0) AS supplier_cost,
        ROW_NUMBER() OVER (PARTITION BY co.o_custkey ORDER BY co.total_revenue DESC) AS revenue_rank
    FROM 
        CustomerOrders co
    LEFT JOIN 
        TopSuppliers tc ON co.o_custkey = tc.s_suppkey
    GROUP BY 
        co.o_orderkey, co.total_revenue, co.o_custkey
)

SELECT 
    ro.o_orderkey,
    ro.total_revenue,
    ro.supplier_cost,
    ro.revenue_rank
FROM 
    RankedOrders ro
WHERE 
    ro.revenue_rank <= 5
ORDER BY 
    ro.total_revenue DESC
LIMIT 10;