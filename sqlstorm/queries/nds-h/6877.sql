WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
        AND o.o_orderdate < DATE '1996-12-31'
),
TopSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_suppkey
    ORDER BY 
        total_supply_cost DESC
    LIMIT 10
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(o.o_totalprice), 0) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    co.c_custkey,
    co.c_name,
    co.total_spent,
    co.order_count,
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_orderstatus,
    ts.ps_suppkey,
    ts.total_supply_cost 
FROM 
    CustomerOrderSummary co
JOIN 
    RankedOrders ro ON co.order_count > 3 AND ro.rn <= 5
JOIN 
    TopSuppliers ts ON ro.o_totalprice > 500 AND ts.ps_suppkey = (SELECT ps_suppkey FROM partsupp WHERE ps_availqty > 50 LIMIT 1)
WHERE 
    co.total_spent > 1000
ORDER BY 
    co.total_spent DESC, ro.o_orderdate DESC;