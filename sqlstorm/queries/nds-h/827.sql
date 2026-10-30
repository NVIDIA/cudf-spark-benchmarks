
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rev_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), 
TopRevenueOrders AS (
    SELECT 
        o_orderkey, 
        o_orderdate, 
        total_revenue
    FROM 
        RankedOrders
    WHERE 
        rev_rank <= 5
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    t.o_orderkey, 
    t.o_orderdate, 
    t.total_revenue, 
    s.s_name,
    COALESCE(s.total_supply_cost, 0) AS total_supply_cost
FROM 
    TopRevenueOrders t
LEFT JOIN 
    SupplierDetails s ON t.o_orderkey = s.s_suppkey
ORDER BY 
    t.total_revenue DESC, 
    t.o_orderdate ASC
