WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '2000-01-01'
),
TopOrders AS (
    SELECT 
        r.o_orderkey, 
        r.o_orderdate, 
        r.o_totalprice
    FROM 
        RankedOrders r
    WHERE 
        r.order_rank <= 100
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 1000.00
)
SELECT 
    o.o_orderkey, 
    o.o_orderdate, 
    o.o_totalprice, 
    s.s_name, 
    s.nation_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    TopOrders o
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    SupplierDetails s ON l.l_suppkey = s.s_suppkey
GROUP BY 
    o.o_orderkey, 
    o.o_orderdate, 
    o.o_totalprice, 
    s.s_name, 
    s.nation_name
ORDER BY 
    revenue DESC 
LIMIT 50;
