WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
), 
TopRecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.c_name
    FROM 
        RankedOrders o
    WHERE 
        o.order_rank <= 5
), 
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= '1996-01-01'
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, s.s_name, s.s_acctbal
)
SELECT 
    t.o_orderkey,
    t.o_orderdate,
    t.o_totalprice,
    p.p_name,
    p.p_retailprice,
    s.s_name AS supplier_name,
    s.total_quantity,
    r.r_name AS region
FROM 
    TopRecentOrders t
JOIN 
    lineitem l ON t.o_orderkey = l.l_orderkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
JOIN 
    PartSupplierDetails s ON p.p_partkey = s.ps_partkey
JOIN 
    nation n ON s.ps_suppkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    t.o_totalprice > 1000
ORDER BY 
    t.o_orderdate DESC, t.o_orderkey;