
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        r.c_name
    FROM 
        RankedOrders r
    WHERE 
        r.order_rank <= 10
),
AggregatedSupplierData AS (
    SELECT 
        ps.ps_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        TopOrders t ON l.l_orderkey = t.o_orderkey
    GROUP BY 
        ps.ps_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        a.total_revenue,
        a.order_count,
        RANK() OVER (ORDER BY a.total_revenue DESC) AS revenue_rank
    FROM 
        supplier s
    JOIN 
        AggregatedSupplierData a ON s.s_suppkey = a.ps_suppkey
)
SELECT 
    t.s_suppkey,
    t.s_name,
    t.total_revenue,
    t.order_count
FROM 
    TopSuppliers t
WHERE 
    t.revenue_rank <= 5
ORDER BY 
    t.total_revenue DESC;
