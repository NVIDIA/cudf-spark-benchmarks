WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        c.c_name, 
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
),
Top10Orders AS (
    SELECT 
        * 
    FROM 
        RankedOrders 
    WHERE 
        price_rank <= 10
),
SupplierInfo AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        p.p_name, 
        p.p_retailprice, 
        p.p_comment
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    t.o_orderkey, 
    t.o_orderdate, 
    t.o_totalprice, 
    t.c_name, 
    s.s_name AS supplier_name, 
    s.p_name AS part_name, 
    s.p_retailprice,
    s.p_comment
FROM 
    Top10Orders t
JOIN 
    lineitem l ON t.o_orderkey = l.l_orderkey
JOIN 
    SupplierInfo s ON l.l_partkey = s.ps_partkey AND l.l_suppkey = s.ps_suppkey
WHERE 
    t.o_totalprice > 10000
ORDER BY 
    t.o_totalprice DESC;