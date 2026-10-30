WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerOrderSummary AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spending
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
)
SELECT 
    n.n_name AS nation_name,
    cos.total_orders,
    cos.total_spending,
    COALESCE(SC.total_supply_cost, 0) AS total_supply_cost,
    COUNT(ro.o_orderkey) AS high_value_orders
FROM 
    nation n
LEFT JOIN 
    CustomerOrderSummary cos ON n.n_nationkey = cos.c_nationkey
LEFT JOIN 
    SupplierCost SC ON SC.ps_partkey IN (
        SELECT 
            l.l_partkey 
        FROM 
            lineitem l 
        JOIN 
            RankedOrders ro ON l.l_orderkey = ro.o_orderkey 
        WHERE 
            ro.order_rank <= 5
    )
LEFT JOIN 
    RankedOrders ro ON ro.o_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_orderstatus = 'F'
    )
GROUP BY 
    n.n_name, cos.total_orders, cos.total_spending, SC.total_supply_cost
ORDER BY 
    total_spending DESC;