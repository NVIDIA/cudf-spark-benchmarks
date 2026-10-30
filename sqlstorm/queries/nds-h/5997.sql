WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_orderstatus, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_status
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1994-01-01' AND o.o_orderdate < DATE '1995-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
TopStatusOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_orderstatus, 
        total_revenue 
    FROM 
        RankedOrders o
    WHERE 
        rank_status <= 10
),
SupplierData AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
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
    t.o_orderstatus, 
    t.total_revenue, 
    s.s_name AS top_supplier, 
    s.total_cost
FROM 
    TopStatusOrders t
JOIN 
    SupplierData s ON t.total_revenue = (SELECT MAX(total_revenue) FROM TopStatusOrders)
ORDER BY 
    t.total_revenue DESC;
