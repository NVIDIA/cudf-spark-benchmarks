WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1995-01-01' AND '1998-12-31'
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
        order_rank <= 10
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name AS supplier_name,
        s.s_acctbal AS supplier_balance
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    t.o_orderkey,
    t.o_orderdate,
    t.total_revenue,
    s.supplier_name,
    s.supplier_balance
FROM 
    TopRevenueOrders t
JOIN 
    lineitem l ON t.o_orderkey = l.l_orderkey
JOIN 
    SupplierDetails s ON l.l_partkey = s.ps_partkey
ORDER BY 
    t.total_revenue DESC, t.o_orderdate ASC;
