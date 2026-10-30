WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        c.c_name, 
        c.c_acctbal, 
        DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
SupplierAggregates AS (
    SELECT 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost, 
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        ra.r_name, 
        sa.total_supply_cost, 
        sa.supplier_count
    FROM 
        SupplierAggregates sa 
    JOIN 
        nation n ON sa.s_nationkey = n.n_nationkey
    JOIN 
        region ra ON n.n_regionkey = ra.r_regionkey
    ORDER BY 
        sa.total_supply_cost DESC 
    LIMIT 5
)
SELECT 
    ro.o_orderkey, 
    ro.o_orderdate, 
    ro.o_totalprice, 
    ro.c_name, 
    ts.r_name AS supplier_region, 
    ts.total_supply_cost, 
    ts.supplier_count 
FROM 
    RankedOrders ro
JOIN 
    TopSuppliers ts ON ro.o_orderkey % 5 = 0
WHERE 
    ro.order_rank <= 10
ORDER BY 
    ro.o_totalprice DESC;