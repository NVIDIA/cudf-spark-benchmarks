WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), 
TopNOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.total_revenue
    FROM 
        RankedOrders o
    WHERE 
        o.rank <= 10
),
SupplierDetails AS (
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
    t.total_revenue,
    s.s_suppkey,
    s.s_name,
    s.total_cost
FROM 
    TopNOrders t
JOIN 
    lineitem l ON t.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    SupplierDetails s ON ps.ps_suppkey = s.s_suppkey
ORDER BY 
    t.total_revenue DESC, s.total_cost ASC;
