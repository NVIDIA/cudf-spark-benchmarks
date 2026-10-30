WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' AND 
        l.l_shipdate >= DATE '1997-01-01' AND 
        l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopRevenueOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        r.total_revenue
    FROM 
        RankedOrders r
    JOIN 
        orders o ON r.o_orderkey = o.o_orderkey
    WHERE 
        r.revenue_rank <= 10
),
SupplierStats AS (
    SELECT 
        s.s_name,
        SUM(ps.ps_supplycost * p.p_retailprice) AS supplier_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_name
)
SELECT 
    tr.o_orderdate,
    tr.o_orderkey,
    tr.total_revenue,
    ss.supplier_value,
    (tr.total_revenue / NULLIF(ss.supplier_value, 0)) AS revenue_per_supplier_value
FROM 
    TopRevenueOrders tr
JOIN 
    SupplierStats ss ON ss.supplier_value > 0
ORDER BY 
    tr.o_orderdate, tr.total_revenue DESC;